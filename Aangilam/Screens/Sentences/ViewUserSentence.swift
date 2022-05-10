//
//  ViewUserSentence.swift
//  Aangilam
//
//  Created by Selvarajan on 10/05/22.
//

import SwiftUI

struct ViewUserSentence: View {
    @State var userSentence: UserSentence
    @State var selection: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Sentence:")
                .font(.headline)
                .padding(.top)
                .foregroundColor(.blue)
            Text("\(userSentence.sentence ?? "")")
                .font(.title2)
                .padding(.bottom)
                
            if (userSentence.tag != nil && !userSentence.tag!.isEmpty) {
                Divider()
                Text("Tag:")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("\(userSentence.tag ?? "")")
            }
            
            NavigationLink(destination: EditUserSentence(userSentence: $userSentence),
                           tag: 1,
                           selection: $selection) {
                EmptyView()
            }
            
            Divider()
            
            Button {
                selection = 1
            } label: {
                Text("Edit Sentence")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame (height: 55)
                    .frame (maxWidth: .infinity)
                    .background (Color.indigo)
                    .cornerRadius(10)
            }
            .padding(.top, 25)
            Spacer()
        }
        .padding()
        .navigationTitle("View Sentence Info")
    }
}

//struct ViewUserSentence_Previews: PreviewProvider {
//    static var previews: some View {
//        ViewUserSentence()
//    }
//}
