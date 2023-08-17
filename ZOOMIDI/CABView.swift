//
//  CABView.swift
//  ZOOMIDI
//
//  Created by Yuichi Yoshida on 2023/08/17.
//

import SwiftUI

struct CABView: View {
    var text: String
    
    enum Note {
        case none
        case sixteenthNote
        case eighthNote
        case quarterNote
        case halfNote
        case wholeNote
    }
    
    var imageType: Note
    
    init(keyword: String) {
        let regrex = /&#x([\w\d]+);\s*(.*?)/
        if let match = keyword.wholeMatch(of: regrex) {
            text = String(match.output.2)
            switch match.output.1 {
            case "1D15D":
                imageType = .wholeNote
            case "1D15E":
                imageType = .halfNote
            case "1D15F":
                imageType = .quarterNote
            case "1D160":
                imageType = .eighthNote
            case "1D161":
                imageType = .sixteenthNote
            default:
                print(keyword)
                imageType = .none
            }
        } else {
            imageType = .none
            text = keyword
        }
    }
    
    var body: some View {
        HStack {
            switch imageType {
            case .sixteenthNote:
                Image("sixteenth_note")
            case .eighthNote:
                Image("eighth_note")
            case .quarterNote:
                Image("quarter_note")
            case .halfNote:
                Image("half_note")
            case .wholeNote:
                Image("whole_note")
            default:
                do {}
            }
            Text(self.text)
        }
    }
}
