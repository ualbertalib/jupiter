class RedirectController < ApplicationController

  skip_after_action :verify_authorized

  def hydra_north_item
    # Note: sometimes '?file=filename' can happen in query string
    return hydra_north_file if params[:file]

    item = find_item_by_noid(noid)
    redirect_to item_url(item), status: :moved_permanently
  end

  def hydra_north_file
    item = find_item_by_noid(noid)
    file = find_item_file(item, params[:filename] || params[:file])
    if file
      redirect_to helpers.file_view_url(file), status: :moved_permanently
    else
      # If file not found, redirect to item level
      redirect_to item_url(item), status: :found
    end
  end

  def hydra_north_community_collection
    object = find_community_or_collection_by_noid(noid)
    redirect_to(polymorphic_path([object.try(:community), object]), status: :moved_permanently)
  end

  def fedora3_item
    item = find_item_by_uuid(uuid)
    redirect_to item_url(item), status: :moved_permanently
  end

  def fedora3_community
    community = find_community_by_uuid(uuid)
    redirect_to community_url(community), status: :moved_permanently
  end

  def fedora3_collection
    collection = find_collection_by_uuid(uuid)
    redirect_to community_collection_url(collection.community, collection), status: :moved_permanently
  end

  def fedora3_datastream
    item = find_item_by_uuid(uuid)
    if /^DS\d+/ !~ params[:ds]
      # If data stream not found, redirect to item level
      return redirect_to item_url(item), status: :found
    end

    unless params[:filename]
      # No filename provided? Redirect to item
      return redirect_to item_url(item), status: :found
    end

    file = find_item_file(item, params[:filename])
    if file
      redirect_to helpers.file_view_url(file), status: :moved_permanently
    else
      # If file not found, redirect to item level
      redirect_to item_url(item), status: :found
    end
  end

  private

  def noid
    # TODO: is it worth doing any pattern matching for format?
    return params[:noid] if params[:noid].present?
    raise JupiterCore::ObjectNotFound
  end

  def find_item_by_noid(noid)
    object = (Item.where(hydra_noid: noid) + Thesis.where(hydra_noid: noid)).first
    return object if object.present?
    raise JupiterCore::ObjectNotFound
  end

  def find_item_file(item, filename)
    return nil if filename.blank?
    item.files.detect { |file| file.blob.filename == CGI.unescape(filename) }
  end

  def find_community_or_collection_by_noid(noid)
    object = (Community.where(hydra_noid: noid) + Collection.where(hydra_noid: noid)).first
    return object if object.present?
    raise JupiterCore::ObjectNotFound
  end

  def uuid
    return params[:uuid] if /^uuid:.+/ =~ params[:uuid]
    raise JupiterCore::ObjectNotFound
  end

  def find_item_by_uuid(uuid)
    object = (Item.where(fedora3_uuid: uuid) + Thesis.where(fedora3_uuid: uuid)).first
    return object if object.present?
    raise JupiterCore::ObjectNotFound
  end

  def find_community_by_uuid(uuid)
    object = Community.where(fedora3_uuid: uuid).first
    return object if object.present?
    raise JupiterCore::ObjectNotFound
  end

  def find_collection_by_uuid(uuid)
    object = Collection.where(fedora3_uuid: uuid).first
    return object if object.present?
    raise JupiterCore::ObjectNotFound
  end

end
