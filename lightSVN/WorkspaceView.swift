//
//  WorkspaceView.swift
//  lightSvn
//
//  Created by suke on 2024/7/5.
//

import SwiftUI
import SwiftyXMLParser

//选中的文件，可能需要文件列表共享，暂时没有用到
class SelectionFiles:ObservableObject{
    @Published var files:Set<FileItem> = Set()
}

struct WorkspaceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var item:Workspace
    @State var info:SVN.Info? = nil
    @State var files:[FileItem] = []
    @State var root:URL?
    @State var stat:SVN.Stat?
    
    @State var showConfirmDeleteWorkspace:Bool = false
    
    
    @State var isActiveInfoView:Bool = true
    @State var onlyShowDirtyFile:Bool = false
    @StateObject var selection = SelectionFiles()
    
    @State var commitViewStat:String = "all"
    
    init(item: Workspace) {
        self.item = item
    }
    
    func setClipboardText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    fileprivate func loadFiles() {
        if item.bookmark == nil{
            return
        }
        DispatchQueue.global().async {
            
            var isStale = false
            do{
                let url = try URL(resolvingBookmarkData: item.bookmark!, options: [.withSecurityScope,.withoutImplicitStartAccessing,.withoutMounting],bookmarkDataIsStale: &isStale)
                root = url
                print("标签过期",isStale)
                if(isStale){
                    return
                }
                let statStr = SVN.Util.shared.stat(url: url.path)
                stat = SVN.Stat.parse(str: statStr)
                //            print(stat?.entries[0].status)
                let _ = url.startAccessingSecurityScopedResource()
                files =  FileItem.loadFiles(url: url) ?? []
                url.stopAccessingSecurityScopedResource()
            }catch{
                
            }
        }
        
        
    }
    
    fileprivate func deleteWorkspace() {
        viewContext.delete(item)
        try! viewContext.save()
    }
    
    fileprivate func InfoItemView(label:String,value:String) -> some View {
        return HStack(alignment:.top){
            HStack{
                Spacer()
                Text(label).multilineTextAlignment(.trailing)
            }.frame(width: 64)
            Text(value).foregroundColor(.secondary)
        }
    }
    
    
    var body: some View {
        VStack(spacing:0){
            
            HStack(spacing:0){
                
                
                
                if((item.bookmark) != nil){
                    VStack(spacing:0){
                        HStack(spacing:2){
                            Button {
                                setClipboardText(item.path ?? "")
                            } label: {
                                Image(systemName: "doc.on.clipboard")
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(item.path ?? "")").font(.callout).foregroundColor(.gray)
                            Spacer()
                            
                        }
                        .padding(4)
                        .padding(.top,2)
                        .padding(.bottom,2)
                        
                        List(selection:$selection.files){
                            FileListView(files: files){item in
                                //                                selectionFiles.insert(item)
                            }
                        }.frame(minWidth:480)
                        
                    }.onChange(of: selection.files) { val in
                        guard let file = selection.files.first else{
                            return
                        }
                        
                        let infoStr = SVN.Util.shared.info(url: file.url.path)
                        info = SVN.Info.fromString(str: infoStr)
                    }
                    
                }
                
                if(isActiveInfoView){
                    //                    Picker(Text("picker"), selection: <#T##Binding<Hashable>#>, content: <#T##() -> View#>)
                    TabView {
                        VStack{
                            
                            ScrollView {
                                if let _info = info  {
                                    if((_info.revision) != nil){
                                        VStack(alignment: .leading,spacing: 2){
                                            InfoItemView(label: "Kind:", value: _info.kind ?? "-")
                                            
                                            InfoItemView(label: "Url:", value: _info.url ?? "-")
                                            
                                            InfoItemView(label: "Path:", value: _info.path ?? "-")
                                            
                                            InfoItemView(label: "Revision:", value: _info.revision ?? "-")
                                            
                                            if let commit = _info.commit {
                                                Section(header:Text("Last Commit").font(.title3).padding(2)) {
                                                    InfoItemView(label: "Author:", value: commit.author)
                                                    InfoItemView(label: "Date:", value: commit.date ?? "")
                                                    InfoItemView(label: "Revision:", value: commit.revision)
                                                }
                                            }
                                            
                                            
                                            Spacer()
                                        }
                                        .padding(4)
                                        .border(.background)
                                    }
                                    
                                }
                                
                            }
                            
                        }.tabItem {
                            Text("Info")
                        }
                        
                        VStack{
                            Text("cmd")
                        }.tabItem {
                            Text("cmd")
                        }
                        
                        
                        List{
                            ForEach(selection.files.sorted(by: { cur, next in
                                return true
                            })) { file in
                                Text(file.url.path)
                            }
                        }
                        .tabItem {
                            Text("selection")
                        }
                        
                        List{
                            if let stat = stat {
                                Text(stat.path)
                                
                                ForEach(stat.entries,id:\.self) { entry in
                                    VStack{
                                        HStack{
                                            Text(entry.path)
                                        }
                                        HStack{
                                            Text(entry.status)
                                            Text(entry.revision ?? "")
                                        }
                                    }
                                }
                                
                            }
                            
                        }.tabItem {
                            Text("stat")
                        }
                        
                        
                        VStack{
                            Picker("", selection: $commitViewStat) {
                                Text("all").tag("all")
                                Text("unversion").tag("unversion")
                                Text("del").tag("del")
                                Text("modify").tag("modify")
                            }.pickerStyle(SegmentedPickerStyle())
                        }.tabItem {
                            Text("commit")
                        }
                        
                    }.frame(minWidth: 240,maxWidth:320)
                        .padding(4)
                    
                }
                
                
            }
            
            
        }
        .navigationTitle(item.name ?? "")
        .onChange(of: onlyShowDirtyFile){
            newVal in
            print("changed onlyShowDirtyFile")
        }
        .onAppear(){
            loadFiles()
            
            if(item.path != nil){
                let str = SVN.Util.shared.info(url: item.path!)
                info = SVN.Info.fromString(str: str)
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    isActiveInfoView.toggle()
                } label: {
                    Label("info",systemImage: "sidebar.right")
                }
                
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    //                    deleteWorkspace()
                    showConfirmDeleteWorkspace = true
                } label: {
                    Label("del",systemImage: "trash")
                }
                
            }
        }.confirmationDialog("确认删除工作区吗?", isPresented: $showConfirmDeleteWorkspace) {
            Button {
                deleteWorkspace()
            } label: {
                Text("Delete")
            }
            
        } message: {
            Text("不可恢复")
        }
        
        
    }
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}


struct FileItem:Identifiable,Hashable {
    var id:String{
        get{
            return url.path
        }
    }
    var url:URL
    var isDir:Bool
    var children:[FileItem]?
    var isDirty:Bool{
        get{
            return dirtyCount > 0
        }
    }
    var dirtyCount:Int = 0
    var stat:SVN.Stat?
    
    public static func loadFiles(url:URL) -> [FileItem]? {
        var result:[FileItem]? = nil
        do{
            var isDir:ObjCBool = false
            
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if(!isDir.boolValue){
                return nil
            }
            let _ = url.startAccessingSecurityScopedResource()
            let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil,options: [])
            url.stopAccessingSecurityScopedResource()
            
            
            
            result = []
            for file in files {
                var isCurrentDir:ObjCBool = false
                FileManager.default.fileExists(atPath: file.path, isDirectory: &isCurrentDir)
                let item = FileItem(url: file,isDir: isCurrentDir.boolValue)
                //                item.children = FileItem.loadFiles(url: file)
                result?.append(item)
            }
            
            
            //            sorted files
            
            let dirs = result!.filter({ $0.isDir }).sorted { cur, next in
                return cur.url.lastPathComponent.localizedCaseInsensitiveCompare(next.url
                    .lastPathComponent) == .orderedAscending
            }
            let others = result!.filter({ !$0.isDir }).sorted { cur, next in
                return cur.url.lastPathComponent.localizedCaseInsensitiveCompare(next.url
                    .lastPathComponent) == .orderedAscending
            }
            
            result = dirs + others
            
        }catch{
            print("load files error:",error)
        }
        return result
    }
}


struct FileListView:View{
    var files:[FileItem]
    var callback:(FileItem)->Void
    
    init(files: [FileItem], callback: @escaping (FileItem) -> Void) {
        self.files = files
        self.callback = callback
    }
    
    var body:some View{
        ForEach(files,id:\.self){
            file in
            FileRowView(file: file){ item in
                callback(item)
            }.tag(file)
        }
        
    }
}

struct FileRowView:View {
    @State var file:FileItem
    @State var isCollap:Bool = false
    
    
    var callback:(FileItem)->Void
    
    init(file: FileItem,callback:@escaping (FileItem)->Void) {
        self.file = file
        self.callback = callback
    }
    
    fileprivate func head(icon:String) -> some View {
        return HStack{
            Image(systemName: icon).foregroundColor(file.isDir ? .blue.opacity(0.8) : .gray)
            Text("\(file.url.lastPathComponent)")
            Spacer()
        }
    }
    
    fileprivate func updateFileStat() {
        DispatchQueue.global().async {
            guard file.url.startAccessingSecurityScopedResource() else{
                return
            }
            let statStr = SVN.Util.shared.stat(url: file.url.path)
            let stat = SVN.Stat.parse(str: statStr)
            DispatchQueue.main.async {
                file.stat = stat
                file.dirtyCount = stat?.entries.count ?? 0
            }
            
            file.url.stopAccessingSecurityScopedResource()
        }
    }
    
    var body: some View {
        
        HStack{
            if(file.isDir){
                Button {
                    isCollap.toggle()
                } label: {
                    Image(systemName:!isCollap ?  "chevron.forward" : "chevron.down")
                        .frame(width: 8,height: 8)
                        .padding(2)
                }.buttonStyle(.plain)
            }else{
                Rectangle().frame(width: 8,height: 8).padding(.trailing,4).foregroundColor(.black.opacity(0))
            }
            head(icon: file.isDir ? "folder.fill" : "doc")
            if(file.isDirty){
                if let stat = file.stat {
                    Text("\(file.dirtyCount) \(stat.entries[0].status)")
                }
                
            }
            
        }
        .contentShape(Rectangle())
        .onChange(of: isCollap) { val in
            if(isCollap){
                file.children = FileItem.loadFiles(url: file.url)
            }
        }
        .onAppear {
            updateFileStat()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { output in
            print("back to front")
            DispatchQueue.global().async {
                updateFileStat()
                if(isCollap){
                    file.children = FileItem.loadFiles(url: file.url)
                }
            }
           
        }
        .contextMenu{
            Button {
                
            } label: {
                Text("menu")
            }
            
        }
        if(file.isDir && (file.children != nil) && isCollap){
            FileListView(files: file.children!){
                item in
                callback(item)
            }
            .padding(.leading)
            .onAppear{
                file.children = FileItem.loadFiles(url: file.url)
            }
        }
        
    }
}
