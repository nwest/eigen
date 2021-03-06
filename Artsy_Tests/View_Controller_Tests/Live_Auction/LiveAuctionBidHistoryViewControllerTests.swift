import Quick
import Nimble
import Nimble_Snapshots
import Interstellar
import UIKit

@testable
import Artsy

class LiveAuctionBidHistoryViewControllerTests: QuickSpec {

    func setupCellWithEvent(event: LiveEvent) -> LiveAuctionHistoryCell {
        let viewModel = LiveAuctionEventViewModel(event: event)
        let subject = LiveAuctionHistoryCell(style: .Value1, reuseIdentifier: "")
        subject.frame = CGRect(x: 0, y: 0, width: 320, height: 50)

        subject.updateWithEventViewModel(viewModel)
        return subject
    }

    override func spec() {
        describe("cells") {
            var subject: LiveAuctionHistoryCell!

            it("looks right for open") {
                let event = LiveEvent(JSON: ["type" : "open", "id" : "OK"])

                subject = self.setupCellWithEvent(event)
                expect(subject).to( haveValidSnapshot() )
            }

            it("looks right for closed") {
                let event = LiveEvent(JSON: ["type" : "closed", "id" : "OK"])

                subject = self.setupCellWithEvent(event)
                expect(subject).to( haveValidSnapshot() )
            }

            it("looks right for bid") {
                let event = LiveEvent(JSON: [
                    "type" : "bid", "id" : "ok",
                    "source" : "floor", "amountCents" : 555_000
                ])

                subject = self.setupCellWithEvent(event)
                expect(subject).to( haveValidSnapshot() )
            }

            it("looks right for final call") {
                let event = LiveEvent(JSON: ["type" : "final_call", "id" : "ok",])

                subject = self.setupCellWithEvent(event)
                expect(subject).to( haveValidSnapshot() )
            }

            it("looks right for fair warning") {
                let event = LiveEvent(JSON: ["type" : "fair_warning", "id" : "ok",])

                subject = self.setupCellWithEvent(event)
                expect(subject).to( haveValidSnapshot() )
            }


        }
    }
}
