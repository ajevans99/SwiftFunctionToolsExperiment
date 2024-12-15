//
//  GPTService.swift
//  SwiftFunctionToolsExperiment
//
//  Created by Austin Evans on 12/14/24.
//

import OpenAI
import JSONSchemaBuilder

struct GPTService {
  private let openAI: OpenAI
  private var tools = [String: ToolProtocol]()

  private let maxIterations: Int

  init(apiKey: String, maxIterations: Int = 3) {
    self.openAI = OpenAI(apiToken: apiKey)
    self.maxIterations = maxIterations
  }

  mutating func registerTool<Output>(
    name: String,
    description: String? = nil,
    schema: some JSONSchemaComponent<Output>,
    handler: @escaping (Output) async throws -> String
  ) {
    tools[name] = AnyTool(name: name, description: description, schema: schema, handler: handler)
  }

  /// Perform the query:
  /// 1. Send the user message and tool definitions to the model.
  /// 2. If the model calls a tool, parse the arguments, run it, feed the result back.
  /// 3. Repeat until a final answer is produced.
  func query(_ userMessage: String) async throws -> String {
    var messages: [ChatQuery.ChatCompletionMessageParam] = [
      .user(.init(content: .string(userMessage)))
    ]

    var iteration = maxIterations
    while iteration >= 0 {
      defer { iteration -= 1 }

      let query = ChatQuery(
        messages: messages,
        model: .gpt4_o,
        tools: tools.map { name, tool in
          ChatQuery.ChatCompletionToolParam(function: .init(name: name, parameters: tool.schemaDefinition()))
        }
      )

      let chatResult = try await openAI.chats(query: query)
      guard let choice = chatResult.choices.first else {
        throw ToolError.unexpectedMessage
      }

      switch choice.message {
      case .assistant(let assistantMessage):
        if let toolCalls = assistantMessage.toolCalls, !toolCalls.isEmpty {
          for toolCall in toolCalls {
            guard let tool = tools[toolCall.function.name] else {
              throw ToolError.noSuchTool
            }

            let toolResult = try await tool.callTool(with: toolCall.function.arguments)
            messages.append(.assistant(.init(toolCalls: [.init(id: toolCall.id, function: toolCall.function)])))
            messages.append(.tool(.init(content: toolResult, toolCallId: toolCall.id)))
          }
        } else {
          // No tool calls means final answer
          return assistantMessage.content ?? ""
        }

      default:
        throw ToolError.unexpectedMessage
      }
    }

    throw ToolError.noResults
  }
}
