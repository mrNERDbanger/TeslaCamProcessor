import SwiftUI

struct ProcessingView: View {
    @ObservedObject var viewModel: VideoProcessorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Processing Videos")
                .font(.title)
                .fontWeight(.bold)
            
            ProgressView(value: viewModel.overallProgress) {
                Text("Overall Progress")
            } currentValueLabel: {
                Text("\(Int(viewModel.overallProgress * 100))%")
            }
            .progressViewStyle(.linear)
            .frame(width: 400)
            
            if let currentTask = viewModel.currentProcessingTask {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Current: \(currentTask)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let detectionCount = viewModel.detectionCounts.first {
                        HStack {
                            Label("\(detectionCount.value) vehicles detected", systemImage: "car")
                                .font(.caption)
                        }
                    }
                }
                .frame(width: 400, alignment: .leading)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.processingLogs, id: \.self) { log in
                        HStack {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(log)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(width: 400, height: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Button("Cancel") {
                    viewModel.cancelProcessing()
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isProcessing)
            }
        }
        .padding(30)
        .frame(width: 500, height: 400)
    }
}