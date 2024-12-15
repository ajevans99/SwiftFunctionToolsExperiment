// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import JSONSchema
import JSONSchemaBuilder
import SwiftDotenv
import OpenAI

let weatherSchema = JSONSchema(weather(location:)) {
  JSONObject {
    JSONProperty(key: "location") {
      JSONString()
        .description("The city")
    }
    .required()
  }
}
.eraseToAnyComponent()

func weather(location: String) -> String {
  print("Hello from weather")
  print("Mocking call for \(location)")
  return "Here's the weather in Paris: 29°C"
}

final class ToolsStore {
  typealias ToolCallID = String

  struct Tool {
    let definition: [String: ChatQuery.JSONValue]
    let onCall: (ToolCallID, String) -> Void
  }

  struct ToolResponse {
    let callID: ToolCallID
    let content: String
  }

  enum ToolError: Error {
    case parseIssue([ParseIssue])
    case decodingError
    case encodingError
  }

  private var storage = [String: Tool]()

  var onRespondToAgent: ((ToolResponse) -> Void)?
  var onFailure: ((ToolError) -> Void)?

  func register(_ name: String, definition: [String: ChatQuery.JSONValue], onCall: @escaping (ToolCallID, String) -> Void) {
    storage[name] = Tool(definition: definition, onCall: onCall)
  }

  func register<Component: JSONSchemaComponent>(_ name: String, schema: Component) where Component.Output: Encodable {
    register(
      name,
      definition: schema.schemaValue.mapValues(ChatQuery.JSONValue.init),
      onCall: { [weak self] callID, content in
        guard let self else { return }

        guard let result = try? schema.parse(instance: content) else {
          onFailure?(.decodingError)
          return
        }

        switch result {
        case .valid(let value):
          guard let data = try? JSONEncoder().encode(value), let content = String(data: data, encoding: .utf8) else {
            onFailure?(.encodingError)
            return
          }
          onRespondToAgent?(.init(callID: callID, content: content))
        case .invalid(let issues):
          onFailure?(.parseIssue(issues))
        }
      }
    )
  }

  func handleToolCall(using parameters: ChatQuery.ChatCompletionMessageParam.ChatCompletionAssistantMessageParam.ChatCompletionMessageToolCallParam) {
    storage[parameters.function.name]?.onCall(parameters.id, parameters.function.arguments)
  }

  func tools() -> [ChatQuery.ChatCompletionToolParam] {
    storage.map { name, tool in
        .init(function: .init(name: name, parameters: tool.definition))
    }
  }
}

struct GPTService {
  private let openAI = OpenAI(apiToken: Dotenv["OPENAI_KEY"]!.stringValue)
  private var toolsStorage = ToolsStore()

  init() {
    toolsStorage.register("get_weather", schema: weatherSchema)

    toolsStorage.onRespondToAgent = {
      dump($0, name: "tool response")
    }
  }

  func query(_ text: String) async throws {
    let query = ChatQuery(
      messages: [
        .user(.init(content: .string(text)))
      ],
      model: .gpt4_o,
      tools: toolsStorage.tools()
    )
    let chatResult = try await openAI.chats(query: query)

    for choice in chatResult.choices {
      switch choice.message {
      case .assistant(let assistant):
        print(assistant.content ?? "")
        assistant.toolCalls?.forEach { toolCallParam in
          toolsStorage.handleToolCall(using: toolCallParam)
        }
      default:
        break
      }
    }
  }
}

@main
struct SwiftFunctionToolsExperiment: AsyncParsableCommand {
  @Argument
  var text: String

  mutating func run() async throws {
    try Dotenv.configure()

    let service = GPTService()
    try await service.query(text)
  }
}

extension ChatQuery.JSONValue {
  init(_ value: JSONValue) {
    switch value {
    case .array(let array): self = .array(array.map(ChatQuery.JSONValue.init))
    case .boolean(let bool): self = .boolean(bool)
    case .integer(let int): self = .integer(int)
    case .number(let number): self = .number(number)
    case .object(let dictionary): self = .object(dictionary.mapValues(ChatQuery.JSONValue.init))
    case .string(let string): self = .string(string)
    case .null: self = .null
    }
  }
}
