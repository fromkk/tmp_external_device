//
//  ContentView.swift
//  File
//
//  Created by Kazuya Ueoka on 2024/06/11.
//

import AVFoundation
import Combine
import SwiftUI

@Observable
final class ViewModel {
  var error: Errors?
  var fileList: [String] = []
  var shouldShowDocumentPicker: Bool = false

  enum Errors: Error {
    case notSupported
    case noPermission
  }

  func requestFileList() async throws {
    guard AVExternalStorageDeviceDiscoverySession.isSupported else {
      error = Errors.notSupported
      return
    }
    guard await AVExternalStorageDevice.requestAccess() else {
      error = Errors.noPermission
      return
    }
    guard let device = AVExternalStorageDeviceDiscoverySession.shared?.externalStorageDevices.first else {
      print("no device")
      return
    }
    print("device displayName \(device.displayName ?? "nil") uuid \(device.uuid?.uuidString ?? "nil") ")
    guard let url = try device.nextAvailableURLs(withPathExtensions: ["mp4"]).first else {
      print("failed to get url")
      return
    }
    print("url \(url)")

    let replacedURL = URL(string: url.absoluteString.replacing(try Regex("100APPLE/.*?$"), with: "100LEICA"))!
    print("replacedURL \(replacedURL)")
    try showFiles(in: replacedURL)
  }

  func showFiles(in url: URL) throws {
    guard url.startAccessingSecurityScopedResource() else {
      print("cannot start accessing security scoped resource")
      return
    }

    fileList = try FileManager.default.contentsOfDirectory(atPath: url.path())

    url.stopAccessingSecurityScopedResource()
  }
}

struct ContentView: View {
  @Bindable var viewModel = ViewModel()

  var body: some View {
    VStack {
      if let error = viewModel.error {
        switch error {
        case .notSupported:
          Text("Not supported")
        case .noPermission:
          Text("No permission")
        }
      } else if !viewModel.fileList.isEmpty {
        ScrollView {
          ForEach(viewModel.fileList, id: \.self) {
            Text("\($0)")
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 16)
          }
        }
      } else {
        Text("No files")
        Button {
          Task {
            do {
              try await viewModel.requestFileList()
            } catch {
              print("unhandled error \(error.localizedDescription)")
            }
          }
        } label: {
          Text("Reload")
        }

        Button {
          viewModel.shouldShowDocumentPicker = true
        } label: {
          Text("Document Picker")
        }
      }
    }
    .task {
      do {
        try await viewModel.requestFileList()
      } catch {
        print("unhandled error \(error.localizedDescription)")
      }
    }
    .sheet(isPresented: $viewModel.shouldShowDocumentPicker, content: {
      DocumentPickerView(selected: { url in
        print("selected url \(url)")
        do {
          try viewModel.showFiles(in: url)
        } catch {
          print("unhandled error \(error)")
        }
      })
        .ignoresSafeArea()
    })
  }
}

#Preview {
    ContentView()
}
