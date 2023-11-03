#!/usr/bin/env python3
import logging
import sys
import asyncio
from lsprotocol import types
from pygls import uris
from pygls.lsp.client import BaseLanguageClient
from pygls.protocol import LanguageServerProtocol
from pygls.protocol import default_converter

class LanguageClient(BaseLanguageClient):
    def __init__(self):
        super().__init__("test-client", "1.0.0", converter_factory=default_converter)
        self.diagnostics: Dict[str, List[types.Diagnostic]] = {}
        self.messages: List[types.ShowMessageParams] = []
        self.log_messages: List[types.LogMessageParams] = []


async def main():
    client = LanguageClient()

    @client.feature(types.WINDOW_LOG_MESSAGE)
    def log_message(client: LanguageClient, params: types.LogMessageParams):
        client.log_messages.append(params)
        levels = ["ERROR: ", "WARNING: ", "INFO: ", "LOG: "]
        log_level = levels[params.type.value - 1]
        print(log_level, params.message)

    @client.feature(types.WINDOW_WORK_DONE_PROGRESS_CREATE)
    def create_work_done_progress(client: LanguageClient, params: types.WorkDoneProgressParams):
        print(params)
    @client.feature(types.PROGRESS)
    def progress(client: LanguageClient, params: types.ProgressParams):
        print(params)
    fixture_dir = sys.argv[2]
    await client.start_io(sys.argv[1], "--lsp")
    response = await client.initialize_async(
        types.InitializeParams(
            capabilities=types.ClientCapabilities(),
            root_path=fixture_dir,
        )
    )
    print(response)

if __name__ == "__main__":
    logging.basicConfig()
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    loop = asyncio.get_event_loop()
    asyncio.ensure_future(main())
    loop.run_forever()
    loop.close()
