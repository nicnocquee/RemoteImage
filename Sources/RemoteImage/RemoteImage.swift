//
//  RemoteImage.swift
//
//  Created by nico on 11.06.19.
//  Copyright © 2019 nico. All rights reserved.
//

import SwiftUI
import Combine

public struct RemoteImage : View {
    var imageURL: String = ""
    var defaultImage: UIImage = UIImage()
    
    @State var image: UIImage?
    let imageFetcher = ImageFetcher()
    
    var body : some View {
        Image(uiImage: self.image ?? defaultImage)
            .onReceive(imageFetcher.fetch(url: imageURL)) { data in
                self.image = UIImage(data: data)
            }
            .onAppear {
                // when it appears, we set the image to cached image if available
                if let cachedImageData = ImageFetcher.cache.object(forKey: NSString(string: self.imageURL)) {
                    self.image = UIImage(data: cachedImageData as Data)
                }
        }
    }
}

class ImageFetcher {
    static let cache = NSCache<NSString, NSData>()
    
    func fetch(url: String) -> AnyPublisher<Data, Never> {
        return Publishers.Future { promise in
            // return image data from cache if available
            if let data = ImageFetcher.cache.object(forKey: NSString(string: url)) {
                DispatchQueue.main.async {
                    promise(.success(data as Data))
                }
                return
            }
            let theURL = URL(string: url)
            
            guard theURL != nil else {
                return
            }
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.requestCachePolicy = .returnCacheDataElseLoad
            
            let session = URLSession(configuration: sessionConfig)
            session.dataTask(with: theURL!) { (data, response, error) in
                if let dat = data {
                    // cache the image
                    ImageFetcher.cache.setObject(NSData(data: dat), forKey: NSString(string: url))
                }
                
                DispatchQueue.main.async {
                    promise(.success(data!))
                }
                }.resume()
            }.eraseToAnyPublisher()
    }
}

struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        RemoteImage()
    }
}
