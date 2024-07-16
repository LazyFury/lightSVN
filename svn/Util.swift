//
//  SvnUtil.swift
//  SuperVersion
//
//  Created by suke on 2024/7/1.
//

import Foundation
import SwiftUI
import SwiftyXMLParser


extension SVN {

    final class Util {
        static let shared = Util()
        
        private init(){
            
        }
        
        private func getConfigDirectory()->String?{
            guard let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else{
                return nil
            }
            
            let svnConfigDirectory = documentsDirectory.appendingPathComponent("svn",isDirectory: true)
            
            return svnConfigDirectory.path
        }

        
        func getProcess()->Process?{
            
            let process = Process()
            
            guard let cli = Bundle.main.url(forResource: "svn", withExtension: nil) else {
                print("没有 svn")
                return nil
            }
            process.launchPath = cli.path
            
            let lib = Bundle.main.url(forResource: "libsvn_client-1.0.dylib", withExtension: nil)
            let libPath = lib?.deletingLastPathComponent()
            let environment = ProcessInfo.processInfo.environment
            var dyldLibraryPath = environment["DYLD_LIBRARY_PATH"] ?? ""
            dyldLibraryPath += ":\(libPath?.path ?? "")"
            process.environment = ["DYLD_LIBRARY_PATH": dyldLibraryPath,
                                   "LANG":"zh_CN.UTF-8"]
            
            return process
        }
        
        func exec(args:Array<String> = [],root:URL? = nil)->String{
            guard let process = SVN.Util.shared.getProcess() else{
                return ""
            }
            
            if(root != nil){
                process.currentDirectoryURL = root
            }
            let svnConfigDir = getConfigDirectory()
            var newArgs:[String] = []
            if((svnConfigDir) != nil){
                newArgs += ["--config-dir",svnConfigDir!]
            }
            newArgs += args
            process.arguments = newArgs
            print(process.arguments ?? "")
            let pipe = Pipe()
            process.standardOutput = pipe
            do{
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let data = String(data:data,encoding: .utf8){
                    print("svn data:",data)
                    return data
                }
            }catch{
                
            }
            return ""
        }
        
        func version()->String{
            return SVN.Util.shared.exec(args: ["--version"])
        }

        func help()->String{
            return SVN.Util.shared.exec(args: ["--help"])
        }

        func info(url:String,args:Array<String> = [])->String{
            return SVN.Util.shared.exec(args: ["info",url,"--xml"] + args)
        }

        func list(url:String,args:Array<String> = [])->String{
            return SVN.Util.shared.exec(args: ["list",url,"--xml"] + args)
        }

        func log(root:URL,target:String,limit:Int=10,args:Array<String> = [])->String{
            return SVN.Util.shared.exec(args: ["log",target,"--xml","--limit",String(describing: limit)] + args,root: root)
        }

        func stat(url:String,args:Array<String> = [])->String{
            return SVN.Util.shared.exec(args: ["stat",url,"--xml"] + args)
        }
        
        func dirtyFileCount(url:String)->Int{
            do{
                let statStr = SVN.Util.shared.exec(args: ["stat",url,"--xml"])
                let stat = try XML.parse(statStr)
                return stat.status.target.entry.compactMap({ xml in
                    return xml
                }).count
            }catch{
                return 0
            }
        }

    }

}
