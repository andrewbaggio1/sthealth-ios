import SwiftUI

struct WorkshopView: View {
    @StateObject private var workshopManager = WorkshopManager.shared
    @State private var messageText = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(workshopManager.messages) { message in
                    HStack {
                        if message.senderType == "user" {
                            Spacer()
                            Text(message.content)
                                .padding()
                                .background(Color.primaryAccent)
                                .foregroundColor(Color.white)
                                .cornerRadius(10)
                        } else {
                            Text(message.content)
                                .padding()
                                .background(Color.secondaryText)
                                .foregroundColor(Color.white)
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                    .padding()
                }
            }

            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    workshopManager.sendMessage(messageText)
                    messageText = ""
                }) {
                    Text("Send")
                }
                .padding()
            }

            Button(action: {
                workshopManager.commitInsight()
            }) {
                Text("Commit Insight")
            }
            .padding()
        }
        .background(Color.primaryBackground)
    }
}