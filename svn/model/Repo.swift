//
//  Repository.swift
//  lightSVN
//
//  Created by suke on 2024/7/15.
//

import Foundation
import SwiftyXMLParser

extension SVN {
    struct Repo:Identifiable,Hashable{
        var id=UUID()
        var kind:String
        var url:String
        var name:String
        var commit:SVN.Commit?
        var children:[Repo]?
        
        public var isDir: Bool {
            get{
                return kind == "dir"
            }
        }
        
        public static func load(url:String) -> [Repo]?{
            let str = SVN.Util.shared.list(url: url)
            let xml = try! XML.parse(str)
            let items: [Repo] = xml["lists"]["list"]["entry"].compactMap { entry in
                let kind = entry.attributes["kind"]
                guard let name = entry["name"].text else{
                    return nil
                }
                let commit = SVN.Commit.fromXml(xml: entry.commit)
                return Repo(kind: kind ?? "", url:url+"/"+name, name: name, commit: commit)
            }
            return items
        }
        
        public mutating func loadChildren(){
            if (self.kind != "dir"){
                return
            }
            self.children = Repo.load(url: url)
        }
    }
}
