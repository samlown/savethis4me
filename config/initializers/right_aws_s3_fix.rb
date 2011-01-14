module RightAws
  class S3
    class Bucket
      # Overwrite the default keys and service method so that the common prefixes are available.
      def keys_and_service(options={}, head=false)
        opt = {}; options.each{ |key, value| opt[key.to_s] = value }
        service_data = {}
        thislist = {}
        list = []
        @s3.interface.incrementally_list_bucket(@name, opt) do |thislist|
          thislist[:contents].each do |entry|
            owner = Owner.new(entry[:owner_id], entry[:owner_display_name])
            key = Key.new(self, entry[:key], nil, {}, {}, entry[:last_modified], entry[:e_tag], entry[:size], entry[:storage_class], owner)
            key.head if head
            list << key
          end
        end
        thislist.each_key do |key|
          service_data[key] = thislist[key] unless (key == :contents) # || key == :common_prefixes)                                                   
        end
        [list, service_data]
      end
    end
  end
end
