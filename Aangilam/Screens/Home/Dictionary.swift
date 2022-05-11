//
//  Dictionary.swift
//  Aangilam
//
//  Created by Selvarajan on 21/04/22.
//

import Foundation
import SwiftUI

class vmDictionary : ObservableObject {
    @Published var wordInfo: WordElement?
    @Published var isFetching: Bool = false
    @Published var definitionFound: Bool?
    
    func fetchData(inputWord: String, searchHistoryVM: SearchHistoryViewModel) {
        if inputWord != "" {
            let stringURL = "https://api.dictionaryapi.dev/api/v2/entries/en/\(inputWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
            guard let url = URL(string: stringURL) else {
                print("Invalid URL")
                self.isFetching = false
                return
            }
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
                guard let data = data, error == nil else {
                    self?.isFetching = false
                    return
                }
                do {
                    let decodedData = try JSONDecoder().decode(Words.self, from: data)
                    DispatchQueue.main.async {
                        self?.wordInfo = decodedData.first!
                        self?.isFetching = false
                        self?.definitionFound = true
                        
                        //saving the search entry in core data
                        searchHistoryVM.saveSearchEntry(word: inputWord, definition: extractMeaning(meanings: decodedData.first!.meanings))
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self?.isFetching = false
                        self?.definitionFound = false
                    }
                    print(error)
                }
            }.resume()
            
        }
    }
    
}

enum PartOfSpeech: String, CaseIterable {
    case noun
    case verb
    case adjective
    case adverb
    case exclamation
    case conjunction
    case pronoun
    case number
    case unknown
}

struct ClearButton: ViewModifier
{
    @Binding var text: String
    @FocusState var searchIsFocused: Bool
    public func body(content: Content) -> some View
    {
        ZStack(alignment: .trailing)
        {
            content

            if !text.isEmpty
            {
                Button(action:
                {
                    self.text = ""
                    self.searchIsFocused = true
                })
                {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(UIColor.opaqueSeparator))
                        .font(.headline)
                }
                .padding(.trailing, 3)
            }
        }
    }
}

struct Dictionary: View {
    @StateObject var userWordListVM = UserWordListViewModel()
    @StateObject var searchHistoryVM = SearchHistoryViewModel()
    @State var dictionaryJson: [String] = []
    @State var filteredItems: [String] = []
    @State private var searchText = ""
    @State var word: WordElement?
    @State private var descriptionField = ""
    @State private var partOfSpeech: PartOfSpeech = .unknown
    @State private var showingAlert = false
    @State private var searchStarted = false
    @StateObject var vmDict = vmDictionary()
    @FocusState private var searchIsFocused: Bool
    
    @Environment(\.presentationMode) var presentationMode
    
    func searchSubmit() {
        searchStarted = true
        vmDict.definitionFound = nil
        vmDict.isFetching = true
        vmDict.fetchData(inputWord: searchText, searchHistoryVM: searchHistoryVM)
    }
    
    var body: some View {
        VStack(alignment: HorizontalAlignment.leading) {
            ScrollView {
                HStack {
                    TextField("Search words in dictionary...", text: $searchText)
                        .modifier(ClearButton(text: $searchText, searchIsFocused: _searchIsFocused))
                        .font(.headline)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 15)
                        .background(.gray.opacity(0.1))
                        .cornerRadius(10)
                        .focused($searchIsFocused)
                        .submitLabel(SubmitLabel.search)
                        .onSubmit {
                            searchSubmit()
                        }
                    
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .padding(.leading, 10)

                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                if (!searchStarted) {
                    //Display previous search terms here
                    ForEach(searchHistoryVM.searchHistoryRecentEntries, id:\.objectID) { searchterm in
                        HStack {
                            HStack{
                                Text(searchterm.word ?? "")
                                    .font(.callout)
                                
                                Text(searchterm.definition ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }.onTapGesture {
                                searchText = searchterm.word ?? ""
                                searchSubmit()
                                searchIsFocused = false
                            }
                            
                            Spacer()
                            Image(systemName: "xmark")
                                .foregroundColor(Color(UIColor.opaqueSeparator))
                                .font(.footnote)
                                .onTapGesture {
                                    searchHistoryVM.deleteSearchEntry(searchEntry: searchterm)
                                }
                        }
                        .padding(.horizontal, 15)
                        .padding(.horizontal)
                        
                        Divider().padding(.horizontal)
                    }
                    if (searchHistoryVM.searchHistoryRecentEntries.count > 0) {
                        Button {
                            // clearing off the history
                            searchHistoryVM.deleteAll()
                        } label: {
                            Text("Clear History")
                                .foregroundColor(.red.opacity(0.8))
                                .font(.footnote)
                        }.padding()
                    }

                }
                
                if (vmDict.isFetching) {
                    Text("Loading definition...")
                        .padding()
                        .foregroundColor(.gray)
                }
                
                if let defFound = vmDict.definitionFound {
                    if (!defFound) {
                        Text("No definition found for '**\(searchText)**'")
                            .padding()
                            .foregroundColor(.red)
                    }
                }
                
                if !vmDict.isFetching && vmDict.wordInfo != nil {
                    VStack(alignment: .leading, spacing: 15) {
                        Text(vmDict.wordInfo?.word.capitalized ?? "")
                            .font(.largeTitle)
                        
                        HStack(spacing: 15) {
                            Text("Phonetics:").font(.headline).foregroundColor(.blue)
                            Text("\(vmDict.wordInfo?.phonetic ?? "") ")
                            Image(systemName: "play.circle")
                        }.padding(.top, 0)
                        
                        Divider()
                        Text("Definition:").font(.headline).foregroundColor(.blue)
                        Text("\(extractMeaning(meanings: vmDict.wordInfo!.meanings))").padding(.top, 0)
                        Divider()
                        
                        if (extractExmple(meanings: vmDict.wordInfo!.meanings) != "") {
                            Text("Example Usage:").font(.headline).foregroundColor(.blue)
                            Text("\(extractExmple(meanings: vmDict.wordInfo!.meanings))").padding(.top, 0)
                        }
                        
                        Button(action: {
                            userWordListVM.saveWord(word: vmDict.wordInfo?.word ?? "",
                                                    tag: "from Dictionary",
                                                    meaning: extractMeaning(meanings: vmDict.wordInfo!.meanings),
                                                    sampleSentence: extractExmple(meanings: vmDict.wordInfo!.meanings))
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("+ Add this word to my list")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame (height: 55)
                                .frame (maxWidth: .infinity)
                                .background (Color.indigo)
                                .cornerRadius(10)
                        })
                    }.padding()
                }
            }
            .onAppear {
                searchHistoryVM.getRecentSearchEntries()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    /// Anything over 0.5 seems to work
                    self.searchIsFocused = true
                }
            }
        }
    }
}

struct Dictionary_Previews: PreviewProvider {
    static var previews: some View {
        Dictionary()
    }
}

