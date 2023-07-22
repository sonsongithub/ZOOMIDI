//
//  ParameterType.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/07/21.
//

import Foundation

enum ParameterType {
    case single(name: String, `default`: Int, max: Int, offset: Int)
    case list(name: String, `default`: Int, max: Int, titles: [String])
    case pair(name: String, `default`: Int, max: [Int], titles: [String])
    case cab(name: String, `default`: Int, max: Int, disp_type: String, disp_max: Int, disp_min: Int, titles: [String])
    case none
}
