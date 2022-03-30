//
//  WordList.swift
//  Mozhi
//
//  Created by Selvarajan on 28/03/22.
//

import SwiftUI

struct WordList: View {
    @StateObject var userWordListVM = UserWordListViewModel()
    
    func delete(at indexes: IndexSet) {
        if let first = indexes.first {
            userWordListVM.userWordAllEntries.remove(at: first)
        }
    }

    var body: some View {
        List {
            ForEach(userWordListVM.userWordAllEntries, id:\.id) {userword in
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(userword.word)")
                            .font(.headline)
                            .bold()
                        Text(" (\(userword.type))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text("\(userword.meaning)").font(.subheadline).foregroundColor(.secondary)
                }
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .navigationTitle(Text("Your Word List"))
        .onAppear {
            userWordListVM.getAllUserWordEntries()
        }
    }
}

struct WordList_Previews: PreviewProvider {
    static var previews: some View {
        WordList()
    }
}
