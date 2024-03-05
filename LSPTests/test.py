#!/usr/bin/env python3
import asyncio
import logging
import pathlib
import sys

from lsprotocol import types
from pygls.lsp.client import BaseLanguageClient
from pygls.protocol import default_converter


class LanguageClient(BaseLanguageClient):
    def __init__(self):
        super().__init__("test-client", "1.0.0", converter_factory=default_converter)

async def main():
    client = LanguageClient()

    @client.feature(types.WINDOW_LOG_MESSAGE)
    def log_message(client: LanguageClient, params: types.LogMessageParams):
        client.log_messages.append(params)
        levels = ["ERROR: ", "WARNING: ", "INFO: ", "LOG: "]
        log_level = levels[params.type.value - 1]
        print(log_level, params.message)

    @client.feature(types.WINDOW_WORK_DONE_PROGRESS_CREATE)
    def create_work_done_progress(
        client: LanguageClient, params: types.WorkDoneProgressParams
    ):
        print(params)

    @client.feature(types.PROGRESS)
    def progress(client: LanguageClient, params: types.ProgressParams):
        print(params)

    @client.feature(types.TEXT_DOCUMENT_PUBLISH_DIAGNOSTICS)
    def diagnostics(client: LanguageClient, params: types.PublishDiagnosticsParams):
        print("DIAGS", params)

    fixture_dir = str(pathlib.Path(sys.argv[2]).parent.resolve())
    await client.start_io(sys.argv[1], "--lsp")
    await client.initialize_async(
        types.InitializeParams(
            capabilities=types.ClientCapabilities(),
            workspace_folders=[types.WorkspaceFolder("file://" + fixture_dir, "root")],
        )
    )
    client.initialized(types.InitializedParams())
    main_meson = "file://" + fixture_dir + "/meson.build"
    await asyncio.sleep(1)
    response = await client.text_document_document_symbol_async(
        types.DocumentSymbolParams(types.TextDocumentIdentifier(main_meson))
    )
    assert len(response) == 1
    response = await client.text_document_inlay_hint_async(
        types.InlayHintParams(
            types.TextDocumentIdentifier(main_meson),
            types.Range(types.Position(0, 0), types.Position(200, 200)),
        )
    )
    assert len(response) == 1
    await client.shutdown_async(None)
    client.exit(None)


if __name__ == "__main__":
    logging.basicConfig()
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    asyncio.run(main())
