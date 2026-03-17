import SwiftUI

struct PostDetail: View {
    var title: String
    var content: String
    var website: String?  
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title)
                .bold()
            
            Text(content)
            
            // Show link if website exists
            if let site = website, let url = URL(string: site.hasPrefix("http") ? site : "https://\(site)") {
                Link("Read more online", destination: url)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Post")
    }
}
