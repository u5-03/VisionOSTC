//
//  VisionOSTCWidget.swift
//  VisionOSTCWidget
//
//  Created by Yugo Sugiyama on 2025/11/19.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // 現在時刻から1時間分のエントリを15分間隔で生成
        let currentDate = Date()
        for minuteOffset in 0 ..< 4 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset * 15, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct VisionOSTCWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.levelOfDetail) var levelOfDetail: LevelOfDetail

    var body: some View {
        switch levelOfDetail {
        case .simplified:
            // 簡略表示
            VStack(spacing: 8) {
                Image(systemName: "visionpro")
                    .font(.title)
                    .foregroundStyle(.blue)
                Text(entry.date, style: .time)
                    .font(.headline)
            }
        default:
            // 通常表示
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "visionpro")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Spacer()
                    Text("TC 2025")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(entry.date, style: .time)
                    .font(.system(size: 32, weight: .bold))

                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 12) {
                    Label("Portal", systemImage: "square.on.square")
                    Label("通知", systemImage: "bell.fill")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct VisionOSTCWidget: Widget {
    let kind: String = "VisionOSTCWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VisionOSTCWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall])
        .supportedMountingStyles([.elevated])
        .configurationDisplayName("visionOS TC")
        .description("visionOS TC 2025のデモWidget")
        .widgetTexture(.paper)
    }
}

#Preview(as: .systemSmall) {
    VisionOSTCWidget()
} timeline: {
    SimpleEntry(date: .now)
}
