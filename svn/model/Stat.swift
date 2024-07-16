//
//  Stat.swift
//  lightSvn
//
//  Created by suke on 2024/7/8.
//

import Foundation
import SwiftyXMLParser


extension SVN{
    class Stat:NSObject,XMLParserDelegate{
        var path:String = ""
        var entries:[Entry] = []
        private var curIndex:Int = -1
        
        struct Entry:Identifiable,Hashable{
            var id = UUID()
            var path:String
            var status:String
            var revision:String?
            var prop:String?
        }
        
        
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            print(attributeDict,elementName)
            
            if(elementName == "target"){
                path = attributeDict["path"] ?? ""
            }
            
            if(elementName == "entry"){
                curIndex += 1
                entries.append(Entry(path: attributeDict["path"] ?? "", status: ""))
            }
            
            if(elementName == "wc-status"){
                entries[curIndex].status = attributeDict["item"] ?? ""
                entries[curIndex].prop = attributeDict["prop"] ?? ""
                entries[curIndex].revision = attributeDict["revision"] ?? ""
            }
        }
        
        public static func parse(str:String)->Stat?{
            print(str)
            let stat = Stat()
            guard let data = str.data(using: .utf8) else {
                return nil
            }
            let parser = XMLParser(data: data)
            parser.delegate = stat
            parser.parse()
            return stat
        }
        
    }
    
}
