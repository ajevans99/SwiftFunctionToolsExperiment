//
//  Tools.swift
//  SwiftFunctionToolsExperiment
//
//  Created by Austin Evans on 12/14/24.
//

import JSONSchemaBuilder
import OpenAI

protocol ToolProtocol {
  var name: String { get }
  var description: String? { get }
  func schemaDefinition() -> [String: ChatQuery.JSONValue]
  func callTool(with arguments: String) async throws -> String
}

enum ToolError: Error {
  case parseIssue([ParseIssue])
  case unexpectedMessage
  case noSuchTool
  case noResults
}

struct AnyTool<Output>: ToolProtocol {
  let _schemaDefinition: [String: ChatQuery.JSONValue]
  let _callTool: (String) async throws -> String

  let name: String
  let description: String?

  init<T: JSONSchemaComponent>(
    name: String,
    description: String?,
    schema: T,
    handler: @escaping (T.Output) async throws -> String
  ) where T.Output == Output {
    self.name = name
    self.description = description
    self._schemaDefinition = schema.schemaValue.mapValues(ChatQuery.JSONValue.init)
    self._callTool = { arguments in
      let parsed = try schema.parse(instance: arguments)
      switch parsed {
      case .valid(let value):
        return try await handler(value)
      case .invalid(let issues):
        throw ToolError.parseIssue(issues)
      }
    }
  }

  func schemaDefinition() -> [String: ChatQuery.JSONValue] {
    _schemaDefinition
  }

  func callTool(with arguments: String) async throws -> String {
    try await _callTool(arguments)
  }
}
