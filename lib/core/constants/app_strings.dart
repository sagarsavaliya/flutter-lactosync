// Centralised string constants — plain language for dairy owners.
abstract final class AppStrings {
  static const appName = 'Lacto Sync';
  static const appTagline = 'Manage your dairy, simply';

  // Sign in
  static const signInTitle = 'Sign in';
  static const signInSubtitle = 'Choose your account type, then sign in';
  static const signInOwnerHint = 'Farm owner — mobile number and 4-digit PIN';
  static const roleFarmOwner = 'Farm owner';
  static const roleCustomer = 'Milk customer';
  static const mobileLabel = 'Mobile number';
  static const mobileHint = '10-digit number';
  static const pinLabel = 'PIN';
  static const pinHint = '4 digits';
  static const newPinLabel = 'New PIN';
  static const confirmPinLabel = 'Confirm PIN';
  static const forgotPin = 'Forgot PIN?';
  static const signIn = 'Sign in';
  static const signOut = 'Sign out';
  static const customerSignInHere = 'Customer? Sign in here';
  static const mobileRequired = 'Enter mobile number';
  static const mobileInvalid = 'Enter valid 10-digit number';
  static const pinRequired = 'Enter PIN';
  static const pinInvalid = 'PIN must be 4 digits';
  static const pinMismatch = 'PINs do not match';
  static const firstNameLabel = 'First name';
  static const lastNameLabel = 'Last name';
  static const firstNameRequired = 'Enter first name';
  static const lastNameRequired = 'Enter last name';

  // Sign up
  static const signupTitle = 'Create account';
  static const signupSubtitle = 'Enter your details — we will ask who you are after OTP';
  static const sendOtp = 'Send OTP on WhatsApp';
  static const alreadyHaveAccount = 'Already have account? Sign in';
  static const createAccount = 'New here? Create account';
  static const setPinTitle = 'Set your PIN';
  static const setPinSubtitle = 'You will use this 4-digit PIN to sign in';

  // Role picker
  static const rolePickerTitle = 'Who are you?';
  static const rolePickerSubtitle = 'Pick the option that matches you';
  static const rolePickerBack = 'Choose a different role';
  static const roleFarmOwnerTitle = 'Dairy farm owner';
  static const roleFarmOwnerSubtitle = 'Manage customers, deliveries and billing';
  static const roleCustomerTitle = 'Milk customer';
  static const roleCustomerSubtitle = 'View deliveries, bills and pause milk';
  static const customerComingSoonTitle = 'Customer app coming soon';
  static const customerComingSoonBody =
      'You will be able to see your milk delivery, bills and vacation requests here. For now, contact your dairy farm directly.';
  static const goToSignIn = 'Go to sign in';
  static const savePin = 'Save PIN';

  // OTP
  static const forgotPinTitle = 'Reset PIN';
  static const forgotPinSubtitle =
      'We will send a 6-digit OTP on WhatsApp';
  static const verifyOtpTitle = 'Enter OTP';
  static const verifyOtpSubtitle = 'Check WhatsApp for the 6-digit code';
  static const otpLabel = 'OTP';
  static const otpHint = '6 digits';
  static const otpRequired = 'Enter OTP';
  static const otpInvalid = 'OTP must be 6 digits';
  static const verifyOtp = 'Verify OTP';
  static const resetPinTitle = 'Set new PIN';
  static const resetPinSubtitle = 'Choose a new 4-digit PIN';
  static const saveNewPin = 'Save new PIN';
  static const pinResetSuccess = 'PIN updated. Sign in with new PIN.';

  // Farm setup
  static const farmSetupTitle = 'Your dairy farm';
  static const farmSetupSubtitle = 'Tell us about your farm';
  static const farmNameLabel = 'Farm name';
  static const farmNameRequired = 'Enter farm name';
  static const addressLabel = 'Address';
  static const addressRequired = 'Enter address';
  static const cityLabel = 'City';
  static const cityRequired = 'Enter city';
  static const stateLabel = 'State';
  static const stateRequired = 'Enter state';
  static const zipLabel = 'PIN code';
  static const zipRequired = 'Enter 6-digit PIN code';
  static const continueLabel = 'Continue';

  // Dashboard setup
  static const setupTitle = 'Setup your farm';
  static const setupSubtitle = 'Complete these steps to start deliveries';
  static const setupFarmDone = 'Farm details';
  static const setupProducts = 'Add milk products';
  static const setupCustomer = 'Add first customer';
  static const setupSubscription = 'Create subscription';
  static const setupDone = 'Done';
  static const setupPending = 'Pending';
  static const goToDashboard = 'Go to dashboard';
  static const dashboardTitle = 'Dashboard';
  static const dashboardGoodMorning = 'Good Morning';
  static const dashboardGoodEvening = 'Good Evening';
  static const dashboardOverviewLabel = 'Dashboard Overview';
  static const dashboardNamaste = 'Namaste';
  static const dashboardNamasteFallback = 'Namaste';
  static const dashboardToday = 'TODAY';
  static const dashboardScheduled = 'SCHEDULED';
  static const dashboardQuickActions = 'Quick Actions';
  static const dashboardViewAll = 'View All';
  static const dashboardFindCustomer = 'Customer';
  static const dashboardGenBill = 'Gen Bill';
  static const dashboardRecordPayment = 'Payment';
  static const dashboardViewQr = 'View QR';
  static const dashboardFindCustomerTitle = 'Find customer';
  static const dashboardViewQrTitle = 'UPI payment QR';
  static const shareQrToCustomer = 'Send QR to customer';
  static const upiNotConfigured = 'Add your UPI ID in Settings first';
  static const qrSentToCustomer = 'Payment QR sent on WhatsApp';
  static const dashboardNavOrders = 'Orders';
  static const dashboardLoadError = 'Could not load dashboard stats';
  static const dashboardSessionError = 'Could not load session';
  static const skipForNow = 'Skip for now';

  // Products
  static const productsTitle = 'Milk products';
  static const productsSubtitle = 'Add at least one product with rate';
  static const productNameLabel = 'Product name';
  static const productNameHint = 'e.g. Premium Cow Milk';
  static const productNameRequired = 'Enter product name';
  static const milkTypeLabel = 'Milk type';
  static const rateLabel = 'Rate (₹)';
  static const rateRequired = 'Enter rate';
  static const unitLabel = 'Unit';
  static const containerLabel = 'Container';
  static const containerKindLabel = 'Container type';
  static const containerSizesLabel = 'Container sizes';
  static const containerSizesRequired = 'Select at least one container size';
  static const productNameAutoHint = 'Auto-generated from milk type and rate';
  static const productsEmptyHint = 'No products yet. Add your milk products.';
  static const addProduct = 'Add product';
  static const saveProducts = 'Save & continue';
  static const removeProduct = 'Remove';

  // Customer
  static const customerTitle = 'Add customer';
  static const customerSubtitle = 'First delivery customer details';
  static const areaLabel = 'Area';
  static const landmarkLabel = 'Landmark';
  static const contactLabel = 'Contact number';
  static const primaryContactLabel = 'Primary contact';
  static const contactRequired = 'Enter contact number';
  static const secondaryContactLabel = 'Secondary contact';
  static const whatsappEnabled = 'WhatsApp on this number?';
  static const whatsappTinyLabel = 'Is WhatsApp?';
  static const customerActive = 'Active customer';
  static const saveCustomer = 'Save customer';

  // After customer
  static const customerSavedTitle = 'Customer saved';
  static const customerSavedSubtitle = 'What would you like to do next?';
  static const createSubscription = 'Set up subscription';
  static const addAnotherCustomer = 'Add another customer';

  // Subscription
  static const subscriptionTitle = 'New subscription';
  static const subscriptionSubtitle = 'Choose customer, product and delivery shift';
  static const selectCustomer = 'Select customer';
  static const selectProduct = 'Select product';
  static const quantityLabel = 'Qty';
  static const quantityLtrLabel = 'Qty (ltr)';
  static const couponLabel = 'Discount';
  static const couponLtrLabel = 'Discount (₹)';
  static const totalLabel = 'Total';
  static const editProduct = 'Edit product';
  static const shiftLabel = 'Delivery shift';
  static const morningShift = 'Morning';
  static const eveningShift = 'Evening';
  static const addMoreProduct = 'Add another product';
  static const createSubscriptionBtn = 'Create';
  static const rateCalculation = 'Your rate';
  static const perLtr = '/ltr';

  // Owner dashboard & navigation
  static const navCustomers = 'Customers';
  static const navDailyOrders = 'Daily Orders';
  static const navBilling = 'Billing';
  static const navPayment = 'Payment';
  static const navSettings = 'Settings';
  static const navHome = 'Home';
  static const kpiCustomers = 'Customers';
  static const kpiSubscriptions = 'Subscriptions';
  static const kpiActive = 'Active';
  static const kpiInactive = 'Inactive';
  static const kpiPaused = 'Paused';
  static const milkPrepTitle = 'Today\'s milk preparation';
  static const milkPrepMorning = 'Morning delivery';
  static const milkPrepEvening = 'Evening delivery';
  static const milkPrepMorningTitle = 'Morning Delivery';
  static const milkPrepEveningTitle = 'Evening Delivery';
  static const milkPrepPremiumGlass = 'Premium (Glass Bottles)';
  static const milkPrepRegularPlastic = 'Regular (Plastic Bags)';
  static const milkPrepGlassBottles = 'Glass Bottles';
  static const milkPrepPlasticBags = 'Plastic Bags';
  static const milkPrepGlass = 'Glass bottles';
  static const milkPrepPlastic = 'Plastic bags';
  static const milkPrepProduct = 'Product';
  static const milkPrepTotal = 'Total';
  static const milkPrepEmpty = 'No containers needed for this shift';
  static const customersScreenTitle = 'Customers';
  static const customersEmpty = 'No customers found';
  static const customersFilterAllProducts = 'All products';
  static const milkPrepCustomersEmpty = 'No customers for this product today';
  static const milkPrepQtySortHigh = 'Quantity high to low';
  static const milkPrepQtySortLow = 'Quantity low to high';
  static const searchCustomersHint = 'Search name, mobile or address';
  static const sortLabel = 'Sort';
  static const sortNameAsc = 'Name A → Z';
  static const sortNameDesc = 'Name Z → A';
  static const sortRecent = 'Recently updated';
  static const sortOldest = 'Oldest updated';
  static const filterAll = 'All';
  static const onVacationLabel = 'On vacation';
  static const comingSoonModule = 'This module is coming soon.';
  static const settingsFarmTitle = 'Farm settings';
  static const settingsTitle = 'Settings';
  static const settingsFarmSection = 'Dairy farm';
  static const settingsOwnerSection = 'Owner profile';
  static const settingsProductsSection = 'Milk products';
  static const settingsTemplatesSection = 'WhatsApp sharing';
  static const settingsWhatsAppImageNote =
      'Bills, milk logs, and payment QR codes are sent as images on WhatsApp so customers can open them on any phone.';
  static const settingsMilkLogTemplate = 'Milk delivery log';
  static const settingsBillingTemplate = 'Billing statement';
  static const settingsPaymentTemplate = 'Payment receipt';
  static const settingsFormatText = 'Text message';
  static const settingsFormatImage = 'Image (WhatsApp)';
  static const settingsIncludeFarmHeader = 'Show farm name on documents';
  static const settingsSave = 'Save changes';
  static const settingsSaved = 'Settings saved';
  static const settingsAddProduct = 'Add product';
  static const settingsEditProduct = 'Edit product';
  static const deleteProductTitle = 'Delete product';
  static const deleteProductConfirm =
      'Remove this product from your catalog? This cannot be undone.';
  static const deleteProductBlocked =
      'This product is linked to a customer subscription. Update those subscriptions first.';
  static const deleteLabel = 'Delete';
  static const deleteProductDone = 'Product removed';
  static const sendOnWhatsApp = 'Send on WhatsApp';
  static const subscriptionsTitle = 'Subscriptions';
  static const paymentsLogTitle = 'Payments log';
  static const shareFailed = 'Could not share. Check WhatsApp is installed.';

  // Daily orders
  static const ordersPending = 'Pending';
  static const ordersDelivered = 'Delivered';
  static const ordersSkipped = 'Skipped';
  static const ordersAllShifts = 'All shifts';
  static const ordersMarkDelivered = 'Mark delivered';
  static const ordersMarkSkipped = 'Skip';
  static const ordersEmpty = 'No orders for this day';
  static const ordersToday = 'Today';
  static const ordersQtyLtr = 'ltr';

  // Billing
  static const billingMonthLabel = 'Month';
  static const billingTotalBilled = 'Billed';
  static const billingCollected = 'Collected';
  static const billingOutstanding = 'Outstanding';
  static const billingPaid = 'Paid';
  static const billingPartial = 'Partial';
  static const billingUnpaid = 'Unpaid';
  static const billingEmpty = 'No bills for this month';
  static const billingDetailTitle = 'Bill detail';
  static const billingLineItems = 'Items';
  static const billingPayments = 'Payments';
  static const billingNoPayments = 'No payments recorded yet';
  static const billingBalance = 'Balance';
  static const billingSendAll = 'Send all bills';
  static const billingSendBill = 'Send bill on WhatsApp';
  static const billingSendBillShort = 'Send';
  static const billingSendSuccess = 'Bill sent on WhatsApp';
  static const billingSendAllSuccess = 'Bills sent to customers';
  static const billingSendFailed = 'Could not send bill';
  static const billingDueDate = 'Due date';
  static const settingsUpiVpa = 'UPI ID (for bill QR)';
  static const settingsUpiPayeeName = 'UPI payee name';

  static const paymentsFilterAll = 'All methods';
  static const paymentsFilterCash = 'Cash';
  static const paymentsFilterUpi = 'UPI';
  static const paymentsFilterBank = 'Bank transfer';
  static const paymentsFilterOther = 'Other';
  static const paymentsCollected = 'Total collected';
  static const paymentsEmpty = 'No payments for this month';
  static const paymentsHandedTo = 'Collected by';

  // Customer detail
  static const customerDetailTitle = 'Customer detail';
  static const editCustomerTitle = 'Edit customer';
  static const deleteCustomerTitle = 'Delete customer?';
  static const deleteCustomerConfirm =
      'This will permanently remove the customer and all their data. This cannot be undone.';
  static const deleteCustomerDone = 'Customer deleted';
  static const deleteCustomerBlocked =
      'Cannot delete — this customer has an unpaid bill. Generate or collect payment first.';
  static const deleteSubscriptionBlockedUnpaid =
      'Cannot remove — clear outstanding bills for this customer first.';
  static const generateBillFromDetail = 'Generate bill for this customer';
  static const recalculateBillTooltip = 'Recalculate bill for this month';
  static const orderLogMorning = 'Morning';
  static const orderLogEvening = 'Evening';
  static const activityTitle = 'Activity log';
  static const activityEmpty = 'No activity recorded yet';
  static const activityRestore = 'Restore';
  static const activityRestored = 'Item restored';
  static const profileActivity = 'Activity log';
  static const profileCommunications = 'Communications';
  static const communicationsTitle = 'Communications';
  static const communicationsEmpty = 'No WhatsApp messages yet';
  static const communicationsSearchHint = 'Search customer or message';
  static const communicationsStatusAll = 'All';
  static const communicationsStatusSent = 'Sent';
  static const communicationsStatusDelivered = 'Delivered';
  static const communicationsStatusRead = 'Read';
  static const communicationsStatusFailed = 'Failed';
  static const communicationsStatusSimulated = 'Simulated';
  static const communicationsSortNewest = 'Newest first';
  static const communicationsSortOldest = 'Oldest first';
  static const editSubscriptionTitle = 'Edit subscription';
  static const saveChanges = 'Save changes';
  static const customerInfoTitle = 'Customer';
  static const consumptionTitle = 'This month consumption';
  static const billingHistoryTitle = 'Billing history';
  static const subscriptionIdLabel = 'Subscription';
  static const couponApplied = 'Discount';
  static const finalRateLabel = 'Final rate';
  static const dailyOrdersTitle = 'Daily orders';
  static const tableDate = 'Date';
  static const tableMorning = 'Mor';
  static const tableEvening = 'Eve';
  static const showMoreBills = 'Show more bills';
  static const showLessBills = 'Show less';
  static const noSubscriptions = 'No subscriptions yet';
  static const noConsumption = 'No deliveries this month';
  static const noConsumptionRecorded = 'No deliveries recorded this month';
  static const noBillingHistory = 'No bills yet';
  static const noBillsGenerated = 'No bills generated yet';
  static const nextBillOnPrefix = 'Next bill on 1st';
  static const noPaymentsThisMonth = 'No payments made for this month';
  static const whatsappYes = 'WhatsApp enabled';
  static const whatsappNo = 'WhatsApp not enabled';
  static const grandTotal = 'Grand total';
  static const billStatusPending = 'Pending';
  static const billStatusPartial = 'Partial paid';
  static const billStatusPaid = 'Fully paid';

  // Profile & vacation
  static const profileMenuTitle = 'Account';
  static const profileMyProfile = 'My profile';
  static const vacationSheetTitle = 'Vacation dates';
  static const vacationStartLabel = 'Stop delivery from';
  static const vacationEndLabel = 'Start delivery again from';
  static const vacationPickDate = 'Pick date';
  static const vacationUpdate = 'Update vacation';
  static const vacationClear = 'Clear vacation';
  static const vacationHint =
      'Milk stops on the first date and resumes on the second date. Applies to all subscriptions.';
  static const vacationActiveNow = 'Customer is on vacation now — deliveries paused';

  // Daily orders
  static const ordersSkip = 'Skip';
  static const ordersQtyLabel = 'Qty';
  static const ordersSearchHint = 'Search customer name';

  // Billing labels
  static const billAmountLabel = 'Bill amount';
  static const billPaidSoFar = 'Paid so far';
  static const billPendingAmount = 'Pending amount';
  static const billFullyPaid = 'Fully paid';
  static const billingPaidShort = 'Paid';
  static const billingPendingShort = 'Pending';
  static const monthActivityTitle = 'This month activity';

  // Subscriptions
  static const subscriptionLabel = 'Subscription';
  static const deleteSubscriptionTitle = 'Delete subscription?';
  static const deleteSubscriptionConfirm =
      'Are you sure you want to remove this subscription? This cannot be undone.';
  static const deleteSubscriptionLastLine = 'At least one subscription line is required';
  static const deleteSubscriptionDone = 'Subscription removed';
  static const deleteSubscriptionBlocked =
      'Cannot remove — this subscription has delivery history';
  static const deliveryTypeLabel = 'Delivery type';
  static const deliveryTypeHomeDelivery = 'Home delivery';
  static const deliveryTypeWalkIn = 'Walk-in';
  static const suspendDeliveryLabel = 'Suspend delivery';
  static const suspendDeliveryHint = 'Stops all deliveries. Not the same as vacation mode.';
  static const addSubscriptionTitle = 'Add subscription';
  static const sendToCustomer = 'Send to customer';
  static const updateOrderLog = 'Update order log';
  /// Compact labels for the milk-log action sheet (two buttons side by side).
  static const sendToCustomerBtn = 'Send';
  static const updateOrderLogBtn = 'Update';
  static const milkLogActionsTitle = 'Milk order log';
  static const milkLogPreparing = 'Preparing order log image…';
  static const milkLogSending = 'Sending order log on WhatsApp…';
  static const milkLogSent = 'Order log image sent to customer';
  static const milkLogSendFailed = 'Could not send order log';
  static const billPreparing = 'Preparing bill image…';
  static const billSending = 'Sending bill on WhatsApp…';
  static const qrPreparing = 'Preparing payment QR…';
  static const qrSending = 'Sending payment QR on WhatsApp…';
  static const selectCustomerForQr = 'Search and select a customer first';
  static const paymentSending = 'Recording payment…';
  static const paymentReceiptSending = 'Sending payment confirmation…';
  static const orderLogUpdated = 'Order log and bill updated';
  static const billRecalcBlocked = 'Cannot update — payment already recorded for this month';

  // FAB actions
  static const generateOrdersTitle = 'Generate daily orders';
  static const orderDateLabel = 'Order date';
  static const generateOrdersButton = 'Generate daily orders';
  static const generateOrdersSuccess = 'Orders created';
  static const generateBillTitle = 'Generate bill';
  static const recalculateBillTitle = 'Recalculate bill';
  static const searchCustomerLabel = 'Search customer';
  static const selectCustomerLabel = 'Select customer';
  static const sendBillOnWhatsApp = 'Send bill on WhatsApp';
  static const generateBillButton = 'Generate bill';
  static const recalculateBillButton = 'Regenerate';
  static const generateBillSuccess = 'Bill generated';
  static const recalculateBillSuccess = 'Bill recalculated';
  static const printBillButton = 'Print';
  static const shareBillButton = 'Share';
  static const shareBillFailed = 'Could not share bill';
  static const collectPaymentTitle = 'Collect payment';
  static const selectPendingBill = 'Pending bill';
  static const paymentAmountLabel = 'Amount';
  static const paymentMethodLabel = 'Payment method';
  static const recordPaymentButton = 'Record payment';
  static const recordPaymentSuccess = 'Payment recorded';

  // Order schedule settings
  static const settingsOrderScheduleSection = 'Daily order schedule';
  static const settingsMorningOrderTime = 'Morning orders at';
  static const settingsEveningOrderTime = 'Evening orders at';
  static const settingsOrderScheduleHint =
      'Orders are created at these times. Customers can also edit or skip until the same cut-off, even after the order is created.';

  // Settings — profile cards (S6-11/12)
  static const settingsEditFarmTitle = 'Edit farm details';
  static const settingsEditOwnerTitle = 'Edit owner profile';
  static const settingsFarmEditTooltip = 'Edit farm details';
  static const settingsOwnerEditTooltip = 'Edit owner profile';
  static const settingsPincodeError = 'Pincode not found, please enter city/state manually';
  static const settingsCityStatePinRow = 'City / State / PIN';
  static const settingsAddressLabel = 'Address';
  static const settingsPinCodeLabel = 'PIN code';
  static const settingsCityLabel = 'City';
  static const settingsStateLabel = 'State';

  // Settings — milk types + container types (S6-13/14/15)
  static const settingsMilkTypesSection = 'Milk types';
  static const settingsContainerTypesSection = 'Container types';
  static const settingsAddMilkType = 'Add milk type';
  static const settingsAddContainerType = 'Add container type';
  static const settingsAddMilkTypeTitle = 'Add milk type';
  static const settingsAddContainerTypeTitle = 'Add container type';
  static const settingsMilkTypeNameLabel = 'Milk type name';
  static const settingsMilkTypeNameHint = 'e.g. A2 Cow';
  static const settingsMilkTypeNameRequired = 'Enter milk type name';
  static const settingsSystemDefault = 'System default';
  static const settingsDeleteTypeTooltip = 'Delete';
  static const settingsMilkTypesEmpty =
      'No milk types visible. Add a custom type or enable a system default.';
  static const settingsContainerTypesEmpty =
      'No container types visible. Add a custom type or enable a system default.';
  static const settingsToggleError = 'Could not update. Please try again.';
  static const settingsDeleteTypeTitle = 'Delete'; // prefix; append type name + '?'
  static const settingsDeleteTypeMessage = 'Remove this type? This cannot be undone.';
  static const settingsDeleteTypeBlocked =
      'Cannot delete — this type is used by a product. Update those products first.';
  static const settingsMilkTypeAdded = 'Milk type added';
  static const settingsMilkTypeRemoved = 'Milk type removed';
  static const settingsContainerTypeAdded = 'Container type added';
  static const settingsMaterialLabel = 'Material';
  static const settingsMaterialHint = 'Select material';
  static const settingsMaterialRequired = 'Select a material';
  static const settingsSizeLabel = 'Size';
  static const settingsSizeHint = 'e.g. 1L, 500ml';
  static const settingsSizeRequired = 'Enter size (e.g. 1L)';

  // OR-07: Container types redesign
  static const settingsContainerTypeNameLabel = 'Name';
  static const settingsContainerTypeNameHint = 'e.g. Stainless Steel Pot';
  static const settingsContainerTypeNameRequired = 'Enter a name';
  static const settingsContainerTypeSizesLabel = 'Sizes';
  static const settingsContainerTypeSizesRequired = 'Add at least one size';
  static const settingsContainerTypeAddSizeLabel = 'Size (litres)';
  static const settingsContainerTypeAddSizeHint = '0.5';
  static const settingsContainerTypeAddSizeTitle = 'Add size';
  static const settingsContainerTypeAddSizeInvalid =
      'Enter a positive decimal number (e.g. 0.5, 1.5)';
  static const settingsContainerTypeRemoveTitle = 'Remove container type?';
  static const settingsContainerTypeRemoveBody =
      'will be removed. Products using this container type will be affected.';
  static const settingsContainerTypeRemoved = 'Container type removed';
  static const settingsContainerTypeRemoveConfirm = 'Remove';

  // OR-08: Product list redesign
  static const settingsProductRemoveTitle = 'Remove product?';
  static const settingsProductRemoveConfirm = 'Remove';
  static const settingsProductRemoved = 'Product removed.';
  static const settingsProductDeleteBlocked =
      "This product can't be deleted — it's currently in use with subscriptions.";
  static const settingsProductAdded = 'Product added.';
  static const settingsProductUpdated = 'Product updated.';
  static const settingsProductAddTitle = 'Add product';
  static const settingsProductEditTitle = 'Edit product';
  static const settingsProductEditTooltip = 'Edit';
  static const settingsProductMilkTypeLabel = 'Milk type';
  static const settingsProductMilkTypeHint = 'Select milk type';
  static const settingsProductMilkTypeRequired = 'Select a milk type';
  static const settingsProductContainerTypeLabel = 'Container type';
  static const settingsProductContainerTypeHint = 'Select container type';
  static const settingsProductContainerTypeRequired = 'Select a container type';
  static const settingsProductRateLabel = 'Rate (₹/ltr)';
  static const settingsProductRateRequired = 'Enter a rate';
  static const settingsProductSaveButton = 'Save product';
  static const settingsProductPreviewLabel = 'Product name';
  static const settingsProductEmpty = 'No products yet.';
  static const settingsProductAddButton = 'Add product';

  // OR-10: Farm address prefill toggle
  static const settingsPrefillToggleTitle = 'Pre-fill customer address from farm';
  static const settingsPrefillToggleHint =
      'When on, city, state and PIN code will be pre-filled from your farm address when adding a new customer.';
  static const settingsPrefillSaveFailed = 'Failed to save setting.';

  // Contact picker
  static const contactsPermissionDenied =
      'Contacts permission denied. Grant it in Settings to use this feature.';
  static const contactNoPhone = 'No phone number found for this contact.';
  static const contactImportError = 'Could not import contact. Please try again.';
  static const importFromContacts = 'Import from contacts';

  // Subscription overdue / suspended (T1-22)
  static const subscriptionSuspendedTitle = 'Subscription Suspended';
  static const subscriptionSuspendedSubtitle =
      'Your subscription has been suspended due to an overdue payment.';
  static const subscriptionPayNow = 'Pay Now';
  static const subscriptionRefreshCheck =
      'Refresh — check if payment was processed';
  static const subscriptionStillSuspended =
      'Subscription is still suspended. Please contact support.';
  static const subscriptionUpiOpenFailed =
      'Could not open UPI app. Please pay manually.';
  static const subscriptionContactSupport =
      'Please contact LactoSync support to clear your dues.';
  static const subscriptionWarningBannerDays =
      'Payment overdue — {n} day(s) left to clear dues';

  // Legacy
  static const registerTitle = 'Create account';
  static const registerSubtitle = 'Set up your farm and sign-in PIN.';
  static const ownerNameLabel = 'Your name';
  static const ownerNameRequired = 'Enter your name';
  static const homeTitle = 'Home';
  static const homeWelcome = 'Welcome';
  static const confirmLabel = 'Confirm';
  static const cancelLabel = 'Cancel';
  static const darkMode = 'Dark mode';
  static const lightMode = 'Light mode';
}
