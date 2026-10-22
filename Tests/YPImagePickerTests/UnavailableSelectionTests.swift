import UIKit
import XCTest
@testable import YPImagePicker

@MainActor
final class UnavailableSelectionTests: XCTestCase {
    func testUnavailablePhotoRefreshesPickerWithoutExporting() {
        assertSelectionIsRefreshed([
            YPLibrarySelection(index: 0, assetIdentifier: "unavailable-photo/L0/001")
        ])
    }

    func testEmptySelectionRefreshesPickerWithoutExporting() {
        assertSelectionIsRefreshed([])
    }

    func testUnavailableMultipleSelectionRefreshesPickerWithoutExporting() {
        assertSelectionIsRefreshed([
            YPLibrarySelection(index: 0, assetIdentifier: "unavailable-photo/L0/001"),
            YPLibrarySelection(index: 1, assetIdentifier: "removed-photo/L0/001")
        ], multipleSelectionEnabled: true)
    }

    private func assertSelectionIsRefreshed(
        _ selection: [YPLibrarySelection],
        multipleSelectionEnabled: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let library = LibrarySpy()
        let delegate = LoadingDelegateSpy()
        library.delegate = delegate
        library.selection = selection
        library.multipleSelectionEnabled = multipleSelectionEnabled
        library.scrollToItem = .photo(p: YPMediaPhoto(image: UIImage()))

        let refreshed = expectation(description: "Picker refreshed after asset access was lost")
        library.onRefresh = {
            XCTAssertTrue(Thread.isMainThread, file: file, line: line)
            XCTAssertTrue(library.selection.isEmpty, file: file, line: line)
            XCTAssertNil(library.scrollToItem, file: file, line: line)
            XCTAssertEqual(delegate.events, ["finished"], file: file, line: line)
            refreshed.fulfill()
        }

        library.selectedMedia(
            photoCallback: { _ in XCTFail("Must not export an unavailable photo", file: file, line: line) },
            videoCallback: { _ in XCTFail("Must not export an unavailable video", file: file, line: line) },
            multipleItemsCallback: { _ in XCTFail("Must not export an incomplete selection", file: file, line: line) }
        )

        wait(for: [refreshed], timeout: 5)
        library.onRefresh = nil
    }
}

private final class LibrarySpy: YPLibraryVC {
    var onRefresh: (() -> Void)?

    override func refreshMediaRequest() {
        onRefresh?()
    }
}

private final class LoadingDelegateSpy: NSObject, YPLibraryViewDelegate {
    var events: [String] = []

    func libraryViewStartedLoading() {
        XCTAssertTrue(Thread.isMainThread)
        events.append("started")
    }

    func libraryViewFinishedLoading() {
        XCTAssertTrue(Thread.isMainThread)
        events.append("finished")
    }

    func libraryViewDidToggleMultipleSelection(enabled: Bool) { }

    func noPhotosForOptions() {
        XCTFail("The library should be refreshed before checking for remaining photos")
    }
}
