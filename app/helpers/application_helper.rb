# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def current_user
    @controller.current_user
  end

  def current_account
    @controller.current_account
  end

  def current_membership
    @controller.current_membership
  end

  def logged_in?
    @controller.logged_in?
  end

  # Generate an upload form to send the file to S3.
  #
  # Required options:
  #  :bucket, :access_key_id, :secret_access_key
  #
  # The provided block *must* include a file field named "file".
  #
  def s3_upload_form(options, html_options = {}, &block)
    raise "Only use s3_upload_form with block!" unless block_given?
    options.reverse_merge!({
      :bucket => '', #req.
      :access_key_id => '', #req.
      :secret_access_key => '', #req.
      :key => '',
      :content_type => '',
      :acl => 'public-read',
      :max_filesize => 2.megabyte,
      :expiration_date => 10.hours.from_now,
    })

    options[:expiration_date] = options[:expiration_date].utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')

    policy = Base64.encode64(
      { 
        'expiration' => options[:expiration_date],
        'conditions' => [
          {'bucket' => options[:bucket]},
          ['starts-with', '$key', options[:key]],
          {'acl' => options[:acl]},
          {'success_action_status' => '201'}, # flash fix?
          ['content-length-range', 0, options[:max_filesize]],
          {'authenticity_token' => form_authenticity_token}, 
          #['starts-with', '$content-type', options[:content_type]],
          ['starts-with', '$filename', ''],
          {'success_action_redirect' => upload_success_new_bucket_archive_url(@bucket)}
        ]
      }.to_json).gsub(/\n|\r/, '')

    #      ['starts-with', '$filename', ''],
    #      ['starts-with', '#{options[:content_type]}', '']
    signature = Base64.encode64( OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        options[:secret_access_key], policy)).gsub("\n", "")

    action = html_options.delete(:action) || "http://#{options[:bucket]}.s3.amazonaws.com/"

    html_options = html_options_for_form(action, html_options.update(:method => :post, :multipart => true))

    # Capture current block outside form_tag to avoid scope problems in Ruby <= 1.8.5
    content = capture(&block)

    form_tag_in_block(html_options) do
      concat hidden_field_tag('key', File.join(options[:key], "${filename}").gsub(/^\//, ''))
      concat hidden_field_tag('AWSAccessKeyId', options[:access_key_id])
      concat hidden_field_tag('acl', options[:acl])
      concat hidden_field_tag('policy', policy)
      concat hidden_field_tag('signature', signature)
      concat hidden_field_tag('success_action_status' , '201')
      #concat hidden_field_tag('content-type', options[:content_type])
      concat hidden_field_tag('filename', '') # Dummy entry for flash crapness
      concat hidden_field_tag('success_action_redirect', upload_success_new_bucket_archive_url(@bucket))
      concat content
    end
  end
    

end
