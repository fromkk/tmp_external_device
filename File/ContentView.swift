//
//  ContentView.swift
//  File
//
//  Created by Kazuya Ueoka on 2024/06/11.
//

import AVFoundation
import Combine
import SwiftUI
import ImageCaptureCore

@Observable
final class ViewModel: NSObject, ICDeviceBrowserDelegate, ICDeviceDelegate {
  var error: Errors?
  var fileList: [String] = []
  var shouldShowDocumentPicker: Bool = false

  enum Errors: Error {
    case notSupported
    case noPermission
  }

  func requestFileList() async throws {
    let browser = ICDeviceBrowser()
    let authorization = await browser.requestContentsAuthorization()
    browser.delegate = self
    switch authorization {
    case .authorized:
      browser.start()
    default:
      throw Errors.noPermission
    }
  }

  func showFiles(in url: URL) throws {
    guard url.startAccessingSecurityScopedResource() else {
      print("cannot start accessing security scoped resource")
      return
    }

    fileList = try FileManager.default.contentsOfDirectory(atPath: url.path())

    url.stopAccessingSecurityScopedResource()
  }

  // MARK: - ICDeviceBrowserDelegate

  func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
    device.delegate = self
    device.requestOpenSession()
  }

  func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
    print("remove \(device)")
  }

  // MAKR: - ICDeviceDelegate

  func didRemove(_ device: ICDevice) {
    print("\(#function)")
  }

  func device(_ device: ICDevice, didOpenSessionWithError error: (any Error)?) {
    print("\(#function) device \(device)")
    if let error {
      print("\(#function) error \(error.localizedDescription)")
    } else if let cameraDevice = device as? ICCameraDevice {
      print("""
\(cameraDevice.description)
contents \(cameraDevice.contents)
mediaFiles \(cameraDevice.mediaFiles)
contentCatalogPercentCompleted \(cameraDevice.contentCatalogPercentCompleted)
isEjectable \(cameraDevice.isEjectable)
""")

      if let contents = cameraDevice.contents {
        print("contents \(contents)")
      }
    }
  }

  func device(_ device: ICDevice, didCloseSessionWithError error: (any Error)?) {
    print("\(#function)")
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
