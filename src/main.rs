use std::env::current_dir;
use std::ops::ControlFlow;
use std::process::Stdio;

use async_lsp::concurrency::ConcurrencyLayer;
use async_lsp::panic::CatchUnwindLayer;
use async_lsp::router::Router;
use async_lsp::tracing::TracingLayer;
use async_lsp::LanguageServer;
use lsp_types::notification::{Progress, PublishDiagnostics, ShowMessage};
use lsp_types::{
    ClientCapabilities, InitializeParams, InitializedParams, NumberOrString, ProgressParamsValue,
    WindowClientCapabilities, WorkDoneProgress,
};
use tokio::io::BufReader;
use tokio::sync::oneshot;
use tower::ServiceBuilder;
use tracing::{info, Level};

struct ClientState {
    indexed_tx: Option<oneshot::Sender<()>>,
}

struct Stop;

#[tokio::main(flavor = "current_thread")]
#[allow(deprecated)]
async fn main() {
    let (indexed_tx, _indexed_rx) = oneshot::channel();

    let (frontend, mut server) = async_lsp::Frontend::new_client(1, |_server| {
        let mut router = Router::new(ClientState {
            indexed_tx: Some(indexed_tx),
        });
        router
            .notification::<Progress>(|this, prog| {
                tracing::info!("{:?} {:?}", prog.token, prog.value);
                if matches!(prog.token, NumberOrString::String(s) if s == "rustAnalyzer/Indexing")
                    && matches!(
                        prog.value,
                        ProgressParamsValue::WorkDone(WorkDoneProgress::End(_))
                    )
                {
                    let _: Result<_, _> = this.indexed_tx.take().unwrap().send(());
                }
                ControlFlow::Continue(())
            })
            .notification::<PublishDiagnostics>(|_, _| ControlFlow::Continue(()))
            .notification::<ShowMessage>(|_, params| {
                tracing::info!("Message {:?}: {}", params.typ, params.message);
                ControlFlow::Continue(())
            })
            .event(|_, _: Stop| ControlFlow::Break(Ok(())));

        ServiceBuilder::new()
            .layer(TracingLayer::default())
            .layer(CatchUnwindLayer::new())
            .layer(ConcurrencyLayer::new(4))
            .service(router)
    });

    tracing_subscriber::fmt()
        .with_max_level(Level::DEBUG)
        .with_ansi(true)
        .with_writer(std::io::stderr)
        .init();

    let child = tokio::process::Command::new("Swift-MesonLSP")
        .arg("--lsp")
        .arg("--stdio")
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

    // Initialize.
    let init_ret = server
        .initialize(InitializeParams {
            root_path: Some(root_dir.into_os_string().into_string().unwrap()),
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
    server.initialized(InitializedParams {}).await.unwrap();

    // Shutdown.
    server.shutdown(()).await.unwrap();
    server.exit(()).await.unwrap();

    server.emit(Stop).await.unwrap();
    frontend_fut.await.unwrap();
}

