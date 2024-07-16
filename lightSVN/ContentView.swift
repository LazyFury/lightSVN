//
//  ContentView.swift
//  SuperVersion
//
//  Created by suke on 2024/7/1.
//

import SwiftUI
import CoreData
import UserNotifications
import AppKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var output:String = "";
    @State private var showAddSvnView = false
    @State var waitUpdateWorkspace:[Workspace] = []
    @State private var input:String = ""
    @State var loadingWorkspace:Bool = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Workspace.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Workspace>
    
    init(){
        print("init content View")
    }
    
    private func sendNotification(name:String) {
        // Step 2: Create the notification content
        let content = UNMutableNotificationContent()
        content.title = name
        content.body = "添加工作区成功!"
        content.sound = UNNotificationSound.default
        
        // Step 3: Create the notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Step 4: Create the notification request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // Step 5: Add the notification request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }
    
    
    fileprivate func creteNewWorkspace(_ result: SVN.Info) {
        print("Add Workspace!")
        
        do {
            let newItem = Workspace(context: viewContext)
            newItem.timestamp = Date()
            newItem.path = result.path
            newItem.bookmark = result.bookmark
            newItem.name = result.fileUrl?.lastPathComponent
            newItem.url = result.fileUrl
            try viewContext.save()
//            sendNotification(name: result.fileUrl?.lastPathComponent ?? "")
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    fileprivate func refreshWorkspace(item:Workspace) {
        var isStale = false
        if(item.bookmark == nil){
            return
        }
        do{
            let url = try URL(resolvingBookmarkData: item.bookmark!, bookmarkDataIsStale: &isStale   )
            let count = SVN.Util.shared.dirtyFileCount(url: url.path)
            
            DispatchQueue.main.async {
                item.clean = count == 0
                item.dirtyCount = Int16(count)
                do{
                    try viewContext.save()
                }catch{
                    
                }
            }
        }catch{
            
        }
    }
    
    fileprivate func refreshAllWorkspace() {
        loadingWorkspace = true
        DispatchQueue.global().async {
            print("Start \(loadingWorkspace)")
            for item in items{
                refreshWorkspace(item: item)
                print("=======================================")
            }
            DispatchQueue.main.async {
                print("End \(loadingWorkspace)")
                loadingWorkspace = false
            }
        }
    }
    
    fileprivate func AddWorkspaceView() -> AddNewWorkspaceView {
        return AddNewWorkspaceView { result in
            creteNewWorkspace(result)
        }
    }
    
    var body: some View {
        NavigationView {
            
            VStack{
                
                
                
                List {
                    NavigationLink(destination:AddWorkspaceView(), isActive: $showAddSvnView){
                        Label("Add Workspace",systemImage: "plus")
                    }.navigationTitle("Add Workspace")
                    
                    Section(header: HStack(spacing:2){
                        Image(systemName: "books.vertical.fill").foregroundColor(.green).padding(.bottom,2)
                        Text("Workspace").font(.custom("logo", size: 12))
                        Button {
                            refreshAllWorkspace()
                        } label: {
                            if(loadingWorkspace){
                                ProgressView()
                                    .progressViewStyle(.automatic)
                                    .scaleEffect(0.4)
                                    .frame(width: 12,height: 12,alignment: .center)
                            }else{
                                Image(systemName: "arrow.circlepath").resizable().frame(width: 12,height: 12)
                            }
                        }.buttonStyle(.plain)
                    }
                        .padding(.bottom,2)){
                            
                            ForEach(items,id:\.self) { item in
                                NavigationLink {
                                    WorkspaceView(item: item)
                                } label: {
                                    HStack(spacing:2){
                                        Button {
                                            item.collected.toggle()
                                            try! viewContext.save()
                                        } label: {
                                            Image(systemName: !item.collected ? "star" : "star.fill")
                                                .foregroundColor(!item.collected ? .gray : .yellow)
                                        }.buttonStyle(.plain)
                                            .padding(2)
                                        
                                        if(!item.clean){
                                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                                            Text("(\(item.dirtyCount))")
                                        }else{
                                            Image(systemName: "checkmark.square.fill").foregroundColor(.blue)
                                        }
                                        
                                        
                                        Text(item.name ?? "-").font(.subheadline)
                                        Spacer()
                                        
                                    }
                                    
                                    .onAppear {
                                        loadingWorkspace = true
                                        DispatchQueue.global().asyncAfter(deadline:.now()){
                                            refreshWorkspace(item:item)
                                            DispatchQueue.main.async{
                                                loadingWorkspace = false
                                            }
                                        }
                                        
                                    }
                                    
                                    
                                }
                            }
                            .onDelete(perform: deleteItems)
                            .onAppear{
                                
                                
                                
                            }
                            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { output in
                                print("back to front")
                                refreshAllWorkspace()
                            }
                            
                        }
                    
                    Section(header: HStack(spacing:2){
                        Image(systemName: "bolt.horizontal.circle").foregroundColor(.blue)
                        Text("Browser")
                        Button {
                            
                        } label: {
                            HStack(spacing:0){
                                Image(systemName:"plus").foregroundColor(.blue)
                                Text("New").foregroundColor(.blue)
                            }
                        }.buttonStyle(.plain)
                        
                    }) {
                        
                        NavigationLink{
                            RepositoryView(input: "https://192.168.10.129/svn/jquery_workspace/2024")
                        }label:{
                            Text("Projects 2024")
                        }
                        
                        
                        NavigationLink{
                            RepositoryView(input: "https://192.168.10.129/svn/jquery_workspace/2023")
                        }label:{
                            Text("2023")
                        }
                        
                        
                        NavigationLink{
                            RepositoryView(input: "https://192.168.10.129/svn/jquery_workspace/2020")
                        }label:{
                            Text("2020")
                        }
                        
                        NavigationLink{
                            RepositoryView(input: "https://192.168.10.129/svn/jquery_workspace/2021")
                        }label:{
                            Text("2021")
                        }
                        
                        NavigationLink{
                            RepositoryView(input: "https://192.168.10.129/svn/jquery_workspace/2022")
                        }label:{
                            Text("2022")
                        }
                        
                    }
                    
                    Section(header: Text("Other")) {
                        
                        
                        NavigationLink {
                            List{
                                Text("setting")
                            }
                        } label: {
                            Text("Setting").font(.subheadline)
                        }
                        
                        
                        
                        NavigationLink {
                            List{
                                HStack{
                                    VStack{
                                        Text(output).onAppear{
                                            output = getSvnVersion()
                                        }.textSelection(.enabled)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .foregroundColor(.gray)
                                .padding(10)
                                .navigationTitle("Version")
                            }
                        } label: {
                            Text("Version").font(.subheadline)
                        }
                      
                        
                        
                        NavigationLink {
                            List{
                                Button {
                                    if let url = URL(string: "https://x.com/kesu1213172") {
                                        NSWorkspace.shared.open(url)
                                    }
                                } label: {
                                    Text("report your question on Twitter With Us")
                                }.buttonStyle(.plain)
                                    .foregroundColor(.blue)

                            }
                        } label: {
                            Text("Report").font(.subheadline)
                        }
                        
                        //                    NavigationLink{
                        //                        WebView(url: URL(string: "https://svnbook.red-bean.com/en/1.7/index.html")!).navigationTitle("Subversion Handbook")
                        //                    } label:{
                        //                        Text("Help").font(.subheadline)
                        //                    }
                    }.collapsible(false)
                    
                }
                .frame(minWidth:240,maxWidth: 360)
                .toolbar {
                    ToolbarItem{
                        Button {
                            print("add project")
#if os(macOS)
                            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
#endif
                        } label: {
                            Label("sidebar",systemImage: "sidebar.left")
                        }
                    }
                    
                }
                
                
                Spacer()
                
                HStack(spacing:2){
                    Image("Logo").resizable().frame(width: 40,height: 40)
                    VStack(alignment: .leading) {
                        Text("lightSVN")
                        Text("trying to do better.").foregroundStyle(.secondary).font(.callout)
                    }
                    Spacer()
                    Button {
                        
                    } label: {
                        Text("Get Pro")
                    }.padding(.horizontal,2)
                        .keyboardShortcut(.defaultAction)
                    
                }.background(.background)
                
                
            }
            .onAppear {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if granted {
                        print("Permission granted")
                    } else if let error = error {
                        print("Error requesting permission: \(error.localizedDescription)")
                    }
                }
            }
            
            HStack{
                VStack{
                    AddWorkspaceView()
                }
            }
            
            
            
        }
    }
    
    func getSvnVersion() -> String{
        return SVN.Util.shared.version()
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Workspace(context: viewContext)
            newItem.timestamp = Date()
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}



#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
