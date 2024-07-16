//
//  Commit.swift
//  lightSvn
//
//  Created by suke on 2024/7/4.
//

import Foundation
import SwiftyXMLParser

extension SVN {
    struct Commit:Hashable,Identifiable{
        var id = UUID()
        var author:String
        var revision:String
        var date:String?
        var msg:String
        
        public static func fromXml(xml:XML.Accessor)->Commit?{
            guard let revision = xml.attributes["revision"] else {return nil}
            let author = xml.author.text ?? "-"
            let msg = xml.msg.text ?? ""
            let dateStr = xml.date.text ?? ""
            
            
            return Commit(author: author, revision: revision, date: dateStr, msg: msg)
        }
    }

}
