//
//  RepositoryView.swift
//  lightSVN
//
//  Created by suke on 2024/7/15.
//

import SwiftUI

struct Row:View {
    @State var item:SVN.Repo
    @State var isCollap:Bool  = false
    
    init(item: SVN.Repo) {
        self.item = item
    }
    
    func setClipboardText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    
    var body: some View {

        HStack{
            if(item.isDir){
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
            
            Image(systemName: item.isDir ? "folder.fill" : "doc").foregroundColor(item.isDir ? .blue.opacity(0.8) : .gray)
            Text("\(item.name)")
            Text("\(item.commit?.author ?? "-") ").foregroundStyle(.gray)
            Button {
                setClipboardText(item.url)
            } label: {
                Text("copy Url")
            }.buttonStyle(.plain)

            Spacer()
            Text("\(item.commit?.date ?? "-") ").foregroundStyle(.gray)


        }.onChange(of: isCollap) { _ in
            item.loadChildren()
        }
        
        if isCollap {
            if let children = item.children {
                ForEach(children) { child in
                    Row(item: child)
                        .padding(.leading)
                }
            }
        }
    }
}

struct RepositoryView: View {
    @State var input:String
    @State var repos:[SVN.Repo] = []
    
    init(input: String) {
        self.input = input
    }
    
    var body: some View {
        VStack(spacing:0){
            HStack{
                HStack{
                    Text("Not implement Auth Yet,place use command line auth")
                }
                Spacer()
                Text("Browser")
                TextField("placeholder...", text: $input).frame(width: 200).cornerRadius(2)
                    
                Button {
                    guard let repos = SVN.Repo.load(url: input) else{
                        return
                    }
                    self.repos = repos
                } label: {
                    Text("Enter")
                }

            }.padding(4)
            
            List {
                ForEach(repos,id: \.self) { repo in
                    Row(item: repo)
                    
                }
            }
            
        }.onAppear {
            if(!input.isEmpty){
                guard let repos = SVN.Repo.load(url: input) else{
                    return
                }
                self.repos = repos
            }
        }
    }
}

#Preview {
    RepositoryView(input: "")
}
