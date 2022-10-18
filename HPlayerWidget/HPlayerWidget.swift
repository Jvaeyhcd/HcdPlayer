//
//  HPlayerWidget.swift
//  HPlayerWidget
//
//  Created by Salvador on 2020/12/23.
//  Copyright © 2020 Salvador. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

enum WidgetError: Error {
    case netError //网络请求出错
    case dataError //数据解析错误
}

/*
 
 由于不支持异步加载图片
 所以暂时在网络请求好之后，直接下载好全部图片
 使用NSCache暂存图片
 */
class WidgetImageLoader {
    
    static var shareLoader = WidgetImageLoader()
    private var cache = NSCache<NSURL, UIImage>()
    
    /// 下载单张图片
    /// - Parameters:
    ///   - imageUrl: 图片URL
    ///   - completion: 成功的回调
    func downLoadImage(imageUrl: String?,completion: @escaping (Result<UIImage, WidgetError>) -> Void) {
        if let imageUrl = imageUrl {
            if let cacheImage  = self.cache.object(forKey: NSURL(string: imageUrl)!) {
                completion(.success(cacheImage))
            } else {
                URLSession.shared.dataTask(with: URL(string: imageUrl)!) { (data, response, error) in
                    if let data = data,
                       let image = UIImage(data: data) {
                        self.cache.setObject(image, forKey: NSURL(string: imageUrl)!)
                        completion(.success(image))
                    } else {
                        completion(.failure(WidgetError.netError))
                    }
                }.resume()
            }
        } else {
            completion(.failure(WidgetError.dataError))
        }
    }
    
    /// 批量下载图片
    /// - Parameters:
    ///   - imageAry: 图片数组集合
    ///   - placeHolder: 占位图，可传可不传
    ///   - completion: 成功回调
    func downLoadImage(imageAry:[String],placeHolder:UIImage?,completion: @escaping (Result<[UIImage], WidgetError>) -> Void) {
        let group:DispatchGroup = DispatchGroup()
        var array = [UIImage]()
        for image in imageAry {
            group.enter()
            self.downLoadImage(imageUrl: image) { result in
                let image : UIImage
                if case .success(let response) = result {
                    image = response
                } else {
                    image = placeHolder ?? UIImage()
                }
                array.append(image)
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion(.success(array))
        }
    }
    
    /// 获取image
    /// - Parameters:
    ///   - imageUrl: 图片地址
    ///   - placeHolderImage: 占位图，请尽量传入
    /// - Returns: 返回结果
    func getImage(_ imageUrl:String, _ placeHolderImage:UIImage?) -> UIImage {
        if let cacheImage  = self.cache.object(forKey: NSURL(string: imageUrl)!) {
            return cacheImage
        } else {
            if let cacheImag = placeHolderImage {
                return cacheImag
            } else {
                return UIImage()
            }
        }
    }
}



struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), url: "", configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), url: "", configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries = [SimpleEntry]()
        let currentDate = Date()
        let midnight = Calendar.current.startOfDay(for: currentDate)
        let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: midnight)!
        let imageUrl = "https://picsum.photos/500?timestamp=" + String(currentDate.timeIntervalSince1970)

        for offset in 0 ..< 60 * 24 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: offset, to: midnight)!
            entries.append(SimpleEntry(date: entryDate, url: imageUrl, configuration: configuration))
        }
        
        WidgetImageLoader.shareLoader.downLoadImage(imageUrl: imageUrl) { result in
            let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
            completion(timeline)
        }
        
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let url: String
    let configuration: ConfigurationIntent
}

struct HPlayerWidgetEntryView : View {
    var entry: Provider.Entry
    
    // 底部遮罩的占比为整体高度的 40%
    var contianerRatio : CGFloat = 0.4
    
    // 从上到下的渐变颜色
    let gradientTopColor: Color = Color.init(red: 0, green: 0, blue: 0, opacity: 0)
    let gradientBottomColor: Color = Color.init(red: 0, green: 0, blue: 0, opacity: 0.35)
    
    // 遮罩视图 简单封装 使代码更为直观
    func gradientView() -> LinearGradient {
        return LinearGradient(gradient: Gradient(colors: [gradientTopColor, gradientBottomColor]), startPoint: .top, endPoint: .bottom)
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 构建 遮罩视图, 使用 frame 确定遮罩大小, 使用 position 定位遮罩位置
                gradientView()
                    .frame(width: geo.size.width, height: geo.size.height * CGFloat(contianerRatio))
                    .position(x: geo.size.width / 2.0, y: geo.size.height * (1 - CGFloat(contianerRatio / 2.0)))
                VStack {
                    Text("hPlayer")
                        .foregroundColor(Color.white)
                    Text(entry.date, style: .time)
                        .foregroundColor(Color.gray).font(.system(size: 12))
                }
                .frame(width: geo.size.width, height: geo.size.height * CGFloat(contianerRatio))
                .position(x: geo.size.width / 2.0, y: geo.size.height * (1 - CGFloat(contianerRatio / 2.0)))
                
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .background(Image(uiImage: WidgetImageLoader.shareLoader.getImage(entry.url, UIImage())))
        }
    }
}

@main
struct HPlayerWidget: Widget {
    let kind: String = "HPlayerWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            HPlayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey("clock_widget"))
        .description(LocalizedStringKey("clock_widget_desc"))
        .supportedFamilies([.systemSmall])
    }
}
