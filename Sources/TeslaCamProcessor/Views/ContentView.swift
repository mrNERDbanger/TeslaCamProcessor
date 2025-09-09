import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = VideoProcessorViewModel()
    @State private var isDraggingOver = false
    @State private var showingSavePanel = false
    @State private var showingProcessingSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("TeslaCam Processor")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isDraggingOver ? Color.blue : Color.gray, style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .background(RoundedRectangle(cornerRadius: 20).fill((isDraggingOver ? Color.blue : Color.gray).opacity(0.1)))
                
                VStack(spacing: 10) {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(isDraggingOver ? .blue : .gray)
                    
                    Text("Drop TeslaCam Videos Here")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text("Supports front, back, left_repeater, right_repeater videos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(40)
            }
            .frame(height: 200)
            .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
                viewModel.handleDroppedVideos(providers: providers)
                return true
            }
            
            if !viewModel.videoFiles.isEmpty {
                VideoListView(videos: viewModel.videoFiles)
                    .frame(maxHeight: 200)
            }
            
            HStack(spacing: 20) {
                Button("Select Output Folder") {
                    showingSavePanel = true
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isProcessing)
                
                Button("Process Videos") {
                    showingProcessingSheet = true
                    viewModel.startProcessing()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.videoFiles.isEmpty || viewModel.isProcessing || viewModel.outputDirectory == nil)
                
                Button("Clear All") {
                    viewModel.clearAll()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isProcessing)
            }
            
            if let outputDir = viewModel.outputDirectory {
                HStack {
                    Image(systemName: "folder")
                    Text("Output: \(outputDir.path)")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingProcessingSheet) {
            ProcessingView(viewModel: viewModel)
        }
        .fileImporter(
            isPresented: $showingSavePanel,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.outputDirectory = url
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
    }
}