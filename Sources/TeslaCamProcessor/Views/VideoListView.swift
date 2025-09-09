import SwiftUI

struct VideoListView: View {
    let videos: [VideoFile]
    
    var groupedVideos: [Date: [VideoFile]] {
        Dictionary(grouping: videos) { video in
            Calendar.current.startOfDay(for: video.timestamp)
        }
    }
    
    var body: some View {
        List {
            ForEach(groupedVideos.keys.sorted(), id: \.self) { date in
                Section(header: Text(dateFormatter.string(from: date))) {
                    ForEach(groupedVideos[date] ?? [], id: \.id) { video in
                        HStack {
                            Image(systemName: iconForAngle(video.angle))
                                .foregroundColor(colorForAngle(video.angle))
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(video.url.lastPathComponent)
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Text("\(video.angle.rawValue.capitalized) Camera")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            statusView(for: video.processingStatus)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
    
    private func iconForAngle(_ angle: VideoFile.CameraAngle) -> String {
        switch angle {
        case .front: return "arrow.up.square"
        case .back: return "arrow.down.square"
        case .left: return "arrow.left.square"
        case .right: return "arrow.right.square"
        }
    }
    
    private func colorForAngle(_ angle: VideoFile.CameraAngle) -> Color {
        switch angle {
        case .front: return .blue
        case .back: return .green
        case .left: return .orange
        case .right: return .purple
        }
    }
    
    @ViewBuilder
    private func statusView(for status: VideoFile.ProcessingStatus) -> some View {
        switch status {
        case .pending:
            Image(systemName: "clock")
                .foregroundColor(.gray)
        case .processing(let progress):
            ProgressView(value: progress)
                .frame(width: 50)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}