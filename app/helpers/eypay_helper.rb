module EypayHelper
  def hidden_fields_for_qpay(params, specific_params = {})
    country = params[:country]
    currency = params[:currency] || Rails.application.config.eypay.currency
    language = params[:language] || Rails.application.config.eypay.language

    # collect required informations for the qpay request
    qpay_options = {
      "customerId"          => Rails.application.config.eypay.logins[country][:customer_id],
      "successURL"          => Rails.application.config.eypay.success_url,
      "failureURL"          => Rails.application.config.eypay.failure_url,
      "cancelURL"           => Rails.application.config.eypay.cancel_url,
      "serviceURL"          => Rails.application.config.eypay.service_url,
      "imageURL"            => Rails.application.config.eypay.logo_url,
      "amount"              => params[:amount],
      "currency"            => currency,
      "language"            => language,
      "orderDescription"    => params[:description],
      "displayText"         => params[:text],
      "customerStatement"   => params[:customer_statement],
      "paymenttype"         => params[:payment_type]
    }.merge(specific_params)

    if Rails.application.config.eypay.confirm_url
      qpay_options["confirmURL"] = Rails.application.config.eypay.confirm_url
    end

    extend_qpay_options_with_fingerprint(qpay_options, :country => country)
    generate_hidden_fields_for_request_to_qpay(qpay_options)
  end

  def hidden_fields_for_qpay_toolkit(params)
    country = params[:country]
    language = params[:language] || Rails.application.config.eypay.language

    # collect required informations for the qpay request
    qpay_options = {
      "customerId"          => Rails.application.config.eypay.logins[country][:customer_id],
      "toolkitPassword"     => Rails.application.config.eypay.logins[country][:toolkit_password],
      "language"            => language,
    }

    toolkit = Eypay::Toolkit.new(qpay_options, params)

    extend_qpay_options_with_fingerprint(toolkit.options, :country => country, :fingerprint_order => toolkit.fingerprint_order)
    generate_hidden_fields_for_request_to_qpay(toolkit.options)
  end

  private

    def extend_qpay_options_with_fingerprint(qpay_options, params = {})
      if params[:fingerprint_order].present?
        fingerprint = Eypay::Fingerprint.new(
          qpay_options,
          :country => params[:country],
          :fingerprint_order => params[:fingerprint_order]
        )
      else
        fingerprint = Eypay::Fingerprint.new(
          qpay_options,
          :country => params[:country]
        )
      end

      qpay_options["RequestFingerprintOrder"] = fingerprint.order
      qpay_options["requestfingerprint"]      = fingerprint.fingerprint
    end

    def generate_hidden_fields_for_request_to_qpay(qpay_options)
      qpay_options.each do |field_name, value|
        concat hidden_field_tag field_name, value
      end
    end
end
