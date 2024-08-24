import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct DocumentPickerView: UIViewControllerRepresentable {
  public let selected: (URL) -> Void
  public init(selected: @escaping (URL) -> Void) {
    self.selected = selected
  }

  public typealias UIViewControllerType = UIDocumentPickerViewController

  public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let documentPicker = UIDocumentPickerViewController.init(forOpeningContentTypes: [.folder], asCopy: false)
    documentPicker.delegate = context.coordinator
    documentPicker.allowsMultipleSelection = true
    return documentPicker
  }

  public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    // nop
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(selected: selected)
  }

  final public class Coordinator: NSObject, UIDocumentPickerDelegate {
    public let selected: (URL) -> Void
    init(selected: @escaping (URL) -> Void) {
      self.selected = selected
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      print("\(#function) \(urls)")
      guard let url = urls.first else { return }
      selected(url)
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      print("\(#function)")
    }
  }
}
