use std::env::current_dir;
use std::ops::ControlFlow;
use std::process::Stdio;
use std::{thread, time::Duration};

use async_lsp::concurrency::ConcurrencyLayer;
use async_lsp::panic::CatchUnwindLayer;
use async_lsp::router::Router;
use async_lsp::tracing::TracingLayer;
use async_lsp::LanguageServer;
use futures::future::join_all;
use lsp_types::notification::{PublishDiagnostics, ShowMessage};
use lsp_types::{
    ClientCapabilities, DidChangeTextDocumentParams, DidOpenTextDocumentParams, HoverParams,
    InitializeParams, InitializedParams, Position, TextDocumentContentChangeEvent,
    TextDocumentIdentifier, TextDocumentItem, TextDocumentPositionParams, Url,
    VersionedTextDocumentIdentifier, WindowClientCapabilities, WorkDoneProgressParams,
};
use std::fs;
use tokio::io::BufReader;
use tower::ServiceBuilder;
use tracing::{info, Level};

struct ClientState {}

struct Stop;

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let (frontend, mut server) = async_lsp::Frontend::new_client(|_server| {
        let mut router = Router::new(ClientState {});
        router
            .notification::<PublishDiagnostics>(|_, _| ControlFlow::Continue(()))
            .notification::<ShowMessage>(|_, params| {
                tracing::info!("Message {:?}: {}", params.typ, params.message);
                ControlFlow::Continue(())
            })
            .event(|_, _: Stop| ControlFlow::Break(Ok(())));

        ServiceBuilder::new()
            .layer(TracingLayer::default())
            .layer(CatchUnwindLayer::default())
            .layer(ConcurrencyLayer::default())
            .service(router)
    });

    tracing_subscriber::fmt()
        .with_max_level(Level::INFO)
        .with_ansi(true)
        .with_writer(std::io::stderr)
        .init();

    let child = tokio::process::Command::new(".build/release/Swift-MesonLSP")
        .arg("--lsp")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .kill_on_drop(true)
        .spawn()
        .expect("Failed run Swift-MesonLSP");
    let stdout = BufReader::new(child.stdout.unwrap());
    let stdin = child.stdin.unwrap();

    let frontend_fut = tokio::spawn(async move {
        frontend.run(stdout, stdin).await.unwrap();
    });

    let root_dir = current_dir()
        .and_then(|path| path.canonicalize())
        .expect("Invalid CWD");
    info!("RootDir: {root_dir:?}");
    // Initialize.
    let init_ret = server
        .initialize(InitializeParams {
            root_path: Some(root_dir.clone().into_os_string().into_string().unwrap()),
            capabilities: ClientCapabilities {
                window: Some(WindowClientCapabilities {
                    work_done_progress: Some(true),
                    ..WindowClientCapabilities::default()
                }),
                ..ClientCapabilities::default()
            },
            ..InitializeParams::default()
        })
        .await
        .unwrap();
    info!("Initialized: {init_ret:?}");
    server.initialized(InitializedParams {}).unwrap();

    // Synchronize documents.
    let file_uri = Url::from_file_path(root_dir.join("meson.build")).unwrap();
    let text = fs::read_to_string(root_dir.join("meson.build")).expect("Huh?");

    thread::sleep(Duration::from_secs(5));
    server
        .did_open(DidOpenTextDocumentParams {
            text_document: TextDocumentItem {
                uri: file_uri.clone(),
                language_id: "meson".into(),
                version: 0,
                text: text.clone(),
            },
        })
        .unwrap();
    // thread::sleep(Duration::from_secs(50));
    let mut count = 0i32;
    info!("Test textDocument/didChange multiple times");
    loop {
        if count == 1000 {
            break;
        }
        count += 1;
        server
            .did_change(DidChangeTextDocumentParams {
                text_document: VersionedTextDocumentIdentifier {
                    uri: file_uri.clone(),
                    version: count,
                },
                content_changes: vec![TextDocumentContentChangeEvent {
                    text: text.clone(),
                    range: None,
                    range_length: None,
                }],
            })
            .unwrap();
    }
    thread::sleep(Duration::from_secs(10));

    count = 0;
    let to_find = vec!["subproject", "returncode", "run_command", "build_machine"];
    info!("Doing textDocument/hover");
    let mut futures = vec![];
    loop {
        if count == 10000 {
            break;
        }
        count += 1;
        let t: &str = to_find[(count as usize) % to_find.len()];
        let var_pos = text.find(t).unwrap();
        futures.push(server.hover(HoverParams {
            text_document_position_params: TextDocumentPositionParams {
                text_document: TextDocumentIdentifier {
                    uri: file_uri.clone(),
                },
                position: Position::new(0, var_pos as _),
            },
            work_done_progress_params: WorkDoneProgressParams::default(),
        }));
    }
    join_all(futures).await;
    // Shutdown.
    // server.shutdown(()).await.unwrap();
    server.exit(()).unwrap();

    server.emit(Stop).unwrap();
    frontend_fut.await.unwrap();
}

