//
//  JSONValueExtensions.swift
//  SwiftFunctionToolsExperiment
//
//  Created by Austin Evans on 12/14/24.
//

import JSONSchema
import OpenAI

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
