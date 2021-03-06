require "../spec_helper"

module Scry
  describe Context do
    it "dispatches commands" do
      context = Context.new

      procedure = Message.from(INITIALIZATION_EXAMPLE)
      result = context.dispatch(procedure)
      result.is_a?(LSP::Protocol::Initialize).should be_true

      procedure = Message.from(CONFIG_CHANGE_EXAMPLE)
      context.dispatch(procedure)

      procedure = Message.from(DOC_OPEN_EXAMPLE)
      context.dispatch(procedure)

      procedure = Message.from(DOC_CHANGE_EXAMPLE)
      context.dispatch(procedure)

      procedure = Message.from(WATCHED_FILE_CHANGED_EXAMPLE)
      context.dispatch(procedure)

      procedure = Message.from(WATCHED_FILE_DELETED_EXAMPLE)
      result = context.dispatch(procedure)
      result.to_json.should eq(%([[{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{"uri":"file://#{SOME_FILE_PATH}","diagnostics":[]}}]]))
    end

    # Test a variety of LSP "methods" to ensure that they ignore files with prefixes that
    # denote a file not physically present (like git:/ or private:/)
    Scry::IN_MEMORY_URI_PREFIXES.each do |ignored_prefix|
      [
        "textDocument/hover",
        "textDocument/definition",
        "textDocument/completion",
        "textDocument/documentSymbol",
        "textDocument/didOpen",
      ].each do |method|
        it "#{method} ignores files prefixed with #{ignored_prefix}" do
          context = Context.new
          procedure = Message.from(get_example_textDocument_message_json(method, "#{ignored_prefix}#{Scry::SOME_FILE_PATH}"))
          expected_response =
            case procedure
            when LSP::Protocol::NotificationMessage # ignored Notification messages just get a nil response
              nil
            else
              LSP::Protocol::ResponseMessage.new(procedure.id, nil)
            end

          result = context.dispatch(procedure)

          result.should eq(expected_response)
        end
      end
    end
  end
end
