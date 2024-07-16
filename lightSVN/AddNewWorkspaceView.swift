//
//  AddSvnFolderView.swift
//  SuperVersion
//
//  Created by suke on 2024/7/1.
//

import SwiftUI
import SwiftyXMLParser

struct SvnInfoView:View {
    
    @State private var info:SVN.Info
    
    init(info: SVN.Info) {
        self.info = info
    }
    
    var body: some View {
        VStack{
            Text("revision:\(info.revision ?? ""    )")
            Text("kind:\(String(describing: info.kind))")
            Text("path:\(String(describing: info.path))")
            Text("url:\(String(describing: info.url))")
            Text("is valid:\(info.isValid ? "valid" : "not valid")")
            
            Text("Last Commit:\(String(describing: info.commit?.author)) \n date:\(String(describing: info.commit?.date)) revision:\(String(describing: info.commit?.revision))")
        }
        .border(.background)
    }
}


struct AddNewWorkspaceView: View {
    
    @State private var selectedFilePath: URL?
    @State private var isFileImporterPresented = false
    @State private var currentInfo:SVN.Info?
    private var callback:(SVN.Info)->Void
    @State private var files:[URL] = []
    
    init(callback: @escaping (SVN.Info) -> Void) {
        self.callback = callback
    }
    
    func reset(){
        selectedFilePath = nil
        isFileImporterPresented = false
        currentInfo = nil
        files = []
    }
    
    fileprivate func tryGetWorkspaceInfo(_ url: URL) {
        let _ = url.startAccessingSecurityScopedResource()
        
        do{
            let str = SVN.Util.shared.info(url: url.path)
            var info = SVN.Info.fromString(str: str)
            if(info.revision != nil){
                currentInfo = info
                print("valid add ")
                info.fileUrl = url
                info.bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                print("callback")
                print(info,info.path ?? "")
                callback(info)
            }
            
            let fileManager = FileManager.default
            files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        }catch{
            print(error)
        }
        url.stopAccessingSecurityScopedResource()
    }
    
    var body: some View {
        
        if(currentInfo != nil){
            SvnInfoView(info: currentInfo!)
        }
        
        if(selectedFilePath != nil){
            Text("Selected File is \(String(describing: selectedFilePath?.path))")
        }
        
        //        ForEach(files,id:\.self){ f in
        //            Text(f.lastPathComponent)
        //
        //        }
        
        if(currentInfo == nil){
            VStack{
                Button {
                    reset()
                    isFileImporterPresented = true
                } label: {
                    Image("Logo").resizable().frame(width: 120,height: 120).foregroundColor(.gray.opacity(0.4))
                }.buttonStyle(.plain)
                
                
                Text("Choose A Folder To Add Svn Workspece!")
                Button {
                    reset()
                    isFileImporterPresented = true
                } label: {
                    Label("Choose Folder",systemImage: "square.and.arrow.up").fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.directory]) { result in
                        let _ = result.map { url in
                            tryGetWorkspaceInfo(url)
                        }
                        
                        
                    }
                }.padding(4)
                
            }
            .padding(.horizontal,120)
            .padding(.vertical,60)
            .background(.quaternary.opacity(0.2))
            .cornerRadius(10)
            
            
        }
    }

}

#Preview {
    AddNewWorkspaceView { result in
        
    }
}
