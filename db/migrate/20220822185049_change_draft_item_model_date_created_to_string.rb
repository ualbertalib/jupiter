class ChangeDraftItemModelDateCreatedToString < ActiveRecord::Migration[6.1]
  def up
    safety_assured { 
      # This migration takes care of moving all the values to the new column
      # type string for date_creted
      
      # Create a new column
      add_column :draft_items, :date_created_string, :string

      # Write to both columns
      DraftItem.class_eval do
        def date_created=(value)
          super(value)
          self[:date_created_string] = value
        end

        def date_created
          return self[:date_created_string] unless self[:date_created_string].nil?

          super
        end
      end

      # Backfill data from the old column to the new column
      execute "UPDATE draft_items SET date_created_string = date_created"

      DraftItem.class_eval do
        # Move reads from the old column to the new column
        def date_created=(value)
          self[:date_created] = value
        end
        # Stop writing to the old column
        def date_created
          self[:date_created]
        end
      end

      # Drop the old column
      remove_column :draft_items, :date_created
      rename_column :draft_items, :date_created_string, :date_created

    }
  end

  def down
    # Create a new column
    add_column :draft_items, :date_created_date, :date

    # Write to both columns
    DraftItem.class_eval do
      def date_created=(value)
        super(value)
        self[:date_created_date] = value
      end

      def date_created
        return self[:date_created_date] unless self[:date_created_date].nil?

        super
      end
    end

    # Backfill data from the old column to the new column
    execute "UPDATE draft_items SET date_created_date = to_date(date_created, 'YYYY-MM-DD')"

    DraftItem.class_eval do
      # Move reads from the old column to the new column
      def date_created=(value)
        self[:date_created] = value
      end
      # Stop writing to the old column
      def date_created
        self[:date_created]
      end
    end

    # Drop the old column
    remove_column :draft_items, :date_created
    rename_column :draft_items, :date_created_date, :date_created  

  end
end
