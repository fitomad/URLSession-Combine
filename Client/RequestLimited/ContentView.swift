//
//  ContentView.swift
//  RequestLimited
//
//  Created by Adolfo Vera Blasco on 20/06/2019.
//  Copyright © 2019 Adolfo Vera Blasco. All rights reserved.
//

import SwiftUI
import Combine
import Foundation

struct ContentView : View
{
    ///
    @State private var isLimitExceed: Bool = false
    
    var body: some View
    {
        NavigationView
        {
            VStack(alignment: .center, spacing: 16)
            {
                HStack(alignment: .center, spacing: 8)
                    {
                        Spacer()
                        
                        Text("3")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text(self.isLimitExceed ? "NO" : "Sí")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                }
                .padding(16)
                
                HStack(alignment: .center, spacing: 8)
                    {
                        Spacer()
                        
                        Text("Peticiones")
                            .font(.footnote)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Disponible")
                            .font(.footnote)
                            .fontWeight(.medium)
                        
                        Spacer()
                }
                .padding(16)
                
                Button(action: self.handleRequestButtonTap) {
                    Text("Lanzar Petición")
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60)
                        .padding(0)
                    
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)
            .padding([ .leading, .trailing, .top, .bottom ], 32)
            .background(Color.yellow)
        }
        
        .navigationBarTitle(Text("URLSession & Combine").font(.largeTitle))
        
    }
    
    // MARK: - Actions -
    
    private func handleRequestButtonTap() -> Void
    {
        self.performRequest()
    }
    
    // MARK: - Network Operations -
    
    private func performRequest() -> Void
    {
        guard let testURL = URL(string: "http://127.0.0.1:5000") else
        {
            return
        }
        
        let publisher = URLSession.shared.dataTaskPublisher(for: testURL)
            .tryMap { (data: Data, response: URLResponse) -> String? in
                guard let httpResponse = response as? HTTPURLResponse else
                {
                    throw MyError.networkError
                }
                
                if httpResponse.statusCode == 429
                {
                    self.isLimitExceed = true
                    
                    throw MyError.requestLimitExceed
                }
                
                return String(data: data, encoding: .utf8)
            }
            .delay(for: 10, scheduler: DispatchQueue.main)
            .retry(1)
            .sink(receiveValue: { (content: String?) -> Void in
                if let content = content
                {
                    print(content)
                }
            })
        
    }
}

enum MyError: Error
{
    case networkError
    case requestLimitExceed
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
