//
//  File.swift
//  lightSvn
//
//  Created by suke on 2024/7/4.
//

import Foundation
import SwiftyXMLParser


extension SVN {
    struct Info {
        public var revision:String?
        public var kind:String?
        public var path:String?
        public var url:String?
        
        public var fileUrl:URL?
        public var bookmark:Data?
        var commit:SVN.Commit?
        
        var isValid:Bool{
            get{
                return revision != nil
            }
        }

        
        struct Repository {
            
        }
        
        public static func fromXml(xml:XML.Accessor)->SVN.Info{
            let revision = xml.info.entry.attributes["revision"];
            let kind = xml.info.entry.attributes["kind"]
            let path = xml.info.entry.attributes["path"]
            let url = xml.info.entry["url"].text
            let commit = Commit.fromXml(xml: xml.info.entry.commit)
            return SVN.Info(revision: revision, kind: kind, path: path, url: url, commit: commit)
        
        }
        
        public static func fromString(str:String)->SVN.Info{
            let xml = try! XML.parse(str)
            return SVN.Info.fromXml(xml: xml)
        }
        
    }

}

