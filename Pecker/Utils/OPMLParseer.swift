//
//  OPMLParseer.swift
//  Pecker
//
//  Created by elanchou on 2024/12/25.
//

import Foundation
import AEXML

class OPMLParser {
    private let logger = Logger(subsystem: "com.elanchou.pecker", category: "opmlparser")
    
    func parseOPML(data: Data) -> OPMLDocument? {
        do {
            // 先将数据转换为字符串进行预处理
            guard let xmlString = String(data: data, encoding: .utf8) else {
                logger.error("Failed to convert data to string")
                return nil
            }
            
            // 清理和转义 XML
            let cleanedXML = cleanXMLString(xmlString)
            guard let cleanedData = cleanedXML.data(using: .utf8) else {
                logger.error("Failed to convert cleaned string back to data")
                return nil
            }
            
            let xmlDoc = try AEXMLDocument(xml: cleanedData)
            
            // 解析 head 部分
            let headElement = xmlDoc.root["head"]
            let head = OPMLHead(
                title: headElement["title"].string,
                dateCreated: headElement["dateCreated"].string,
                dateModified: headElement["dateModified"].string
            )
            
            // 解析 body 部分
            let bodyElement = xmlDoc.root["body"]
            var outlines: [OPMLOutline] = []
            
            // 处理顶层 outline 元素
            for outlineElement in bodyElement["outline"].all ?? [] {
                if let outline = parseOutline(outlineElement) {
                    outlines.append(outline)
                }
            }
            
            let body = OPMLBody(outlines: outlines)
            return OPMLDocument(head: head, body: body)
            
        } catch {
            logger.error("OPML parsing error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func parseOutline(_ element: AEXMLElement) -> OPMLOutline? {
        // 如果有 xmlUrl，说明是一个 feed
        if element.attributes["xmlUrl"] != nil {
            return nil
        }
        
        let title = element.attributes["text"] ?? ""
        var feeds: [OPMLFeed] = []
        
        // 解析子 outline 元素
        for childElement in element["outline"].all ?? [] {
            if let feed = parseFeed(childElement) {
                feeds.append(feed)
            }
        }
        
        return OPMLOutline(title: title, feeds: feeds)
    }
    
    private func parseFeed(_ element: AEXMLElement) -> OPMLFeed? {
        guard let xmlUrl = element.attributes["xmlUrl"] else {
            return nil
        }
        
        return OPMLFeed(
            title: element.attributes["text"],
            xmlUrl: xmlUrl,
            htmlUrl: element.attributes["htmlUrl"],
            description: element.attributes["description"],
            category: element.attributes["category"],
            language: element.attributes["language"]
        )
    }
    
    private func cleanXMLString(_ input: String) -> String {
        var cleaned = input
        
        // 移除 XML 声明（如果存在）
        if let range = cleaned.range(of: "<?xml") {
            if let endRange = cleaned.range(of: "?>") {
                cleaned.removeSubrange(range.lowerBound...endRange.upperBound)
            }
        }
        
        // 转义特殊字符
        cleaned = cleaned.replacingOccurrences(of: "&(?!amp;|lt;|gt;|quot;|apos;)", with: "&amp;", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "<(?![/a-zA-Z])", with: "&lt;")
        cleaned = cleaned.replacingOccurrences(of: "(?<![a-zA-Z/])>", with: "&gt;")
        
        // 移除非法字符
        let illegalCharacters = CharacterSet(charactersIn: "\u{0001}-\u{0008}\u{000B}-\u{000C}\u{000E}-\u{001F}")
        cleaned = cleaned.components(separatedBy: illegalCharacters).joined()
        
        // 修复常见的编码问题
        cleaned = cleaned.replacingOccurrences(of: "& ", with: "&amp; ")
        cleaned = cleaned.replacingOccurrences(of: "&amp;amp;", with: "&amp;")
        cleaned = cleaned.replacingOccurrences(of: "&amp;lt;", with: "&lt;")
        cleaned = cleaned.replacingOccurrences(of: "&amp;gt;", with: "&gt;")
        cleaned = cleaned.replacingOccurrences(of: "&amp;quot;", with: "&quot;")
        cleaned = cleaned.replacingOccurrences(of: "&amp;apos;", with: "&apos;")
        
        // 移除多余的空白字符
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 添加 XML 声明
        cleaned = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + cleaned
        
        return cleaned
    }
}
