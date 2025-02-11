//
//  StringUtils.swift
//  Pecker
//
//  Created by elanchou on 2024/12/10.
//

import UIKit

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
    
    func splitWithGrowingChunks() -> [String] {
            guard !self.isEmpty else { return [] }
            
            var chunks: [String] = []
            var currentChunk = ""
            
            var words: [String] = []
            var currentWord = ""
            
            // 将中英文字符以及空格、标点符号分开处理
            for character in self {
                if character.isChinese || character.isLetter {
                    // 如果是中文或英文字符，作为当前单词的一部分
                    currentWord.append(character)
                } else {
                    // 如果是空格或标点符号，认为是分隔符，结束当前单词
                    if !currentWord.isEmpty {
                        words.append(currentWord)
                        currentWord = ""
                    }
                    // 保留标点符号单独作为一个元素
                    if !character.isWhitespace {
                        words.append(String(character))
                    }
                }
            }
            
            // 处理最后一个单词
            if !currentWord.isEmpty {
                words.append(currentWord)
            }
            
            // 构建每个递增的单元
            for (index, word) in words.enumerated() {
                if index > 0 {
                    currentChunk.append(" ")
                }
                currentChunk.append(word)
                chunks.append(currentChunk)
            }
            
            return chunks
        }
}

extension Character {
    // 判断字符是否为中文字符
    var isChinese: Bool {
        guard let scalar = self.unicodeScalars.first else { return false }
        let codePoint = scalar.value
        return (codePoint >= 0x4E00 && codePoint <= 0x9FFF) || // 基本汉字
               (codePoint >= 0x3400 && codePoint <= 0x4DBF) || // 扩展A
               (codePoint >= 0x20000 && codePoint <= 0x2A6DF) || // 扩展B
               (codePoint >= 0x2A700 && codePoint <= 0x2B73F) || // 扩展C
               (codePoint >= 0x2B740 && codePoint <= 0x2B81F) || // 扩展D
               (codePoint >= 0x2B820 && codePoint <= 0x2CEAF) || // 扩展E
               (codePoint >= 0x2CEB0 && codePoint <= 0x2EBEF) // 扩展F
    }
    
    // 判断字符是否为字母
    var isLetter: Bool {
        guard let scalar = self.unicodeScalars.first else { return false }
        return CharacterSet.letters.contains(scalar)
    }
}
