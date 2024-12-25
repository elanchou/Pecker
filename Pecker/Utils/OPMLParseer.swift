//
//  OPMLParseer.swift
//  Pecker
//
//  Created by elanchou on 2024/12/25.
//

import Foundation

class OPMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentFeed: OPMLFeed?
    private var currentOutline: OPMLOutline?
    private var outlines: [OPMLOutline] = []
    private var feeds: [OPMLFeed] = []
    
    func parseOPML(data: Data) -> OPMLDocument? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        if parser.parse() {
            let body = OPMLBody(outlines: outlines)
            let head = OPMLHead(title: "OPML Document", dateCreated: nil, dateModified: nil)
            return OPMLDocument(head: head, body: body)
        }
        return nil
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "outline" {
            if let xmlUrl = attributeDict["xmlUrl"] {
                currentFeed = OPMLFeed(
                    title: attributeDict["text"] ?? "",
                    xmlUrl: xmlUrl,
                    htmlUrl: attributeDict["htmlUrl"],
                    description: attributeDict["description"],
                    category: attributeDict["category"],
                    language: attributeDict["language"]
                )
            } else {
                currentOutline = OPMLOutline(
                    title: attributeDict["text"] ?? "",
                    feeds: []
                )
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "outline" {
            if let feed = currentFeed {
                feeds.append(feed)
                currentFeed = nil
            } else if let outline = currentOutline {
                outlines.append(outline)
                currentOutline = nil
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // 处理字符数据（如果需要）
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        // 解析结束后，处理数据
        if currentOutline != nil {
            currentOutline!.feeds.append(contentsOf: feeds)
            outlines.append(currentOutline!)
        }
    }
}
