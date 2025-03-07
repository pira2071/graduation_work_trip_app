import { Application } from "@hotwired/stimulus"
import { Controller } from "@hotwired/stimulus"
import SpotsRegistrationController from "./spots_registration_controller"
import MembersController from "./members_controller"
import PackingListFormController from "./packing_list_form_controller"
import PackingListCheckController from "./packing_list_check_controller"
import PhotoController from "./photo_controller"
import SearchAutocompleteController from "./search_autocomplete_controller"
import NotificationController from "./notification_controller"
import TravelLinkController from "./travel_link_controller"
import TravelImageController from "./travel_image_controller"

// Stimulusアプリケーションを開始
const application = Application.start()

// ドロップダウンコントローラー
class DropdownController extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.preventDefault()
    this.menuTarget.classList.toggle('show')
  }
}

application.register("dropdown", DropdownController)
application.register("spots-registration", SpotsRegistrationController)
application.register("members", MembersController)
application.register("packing-list-form", PackingListFormController)
application.register("packing-list-check", PackingListCheckController)
application.register("photo", PhotoController)
application.register("search-autocomplete", SearchAutocompleteController)
application.register("notification", NotificationController)
application.register("travel-link", TravelLinkController)
application.register("travel-image", TravelImageController)

export { application }
