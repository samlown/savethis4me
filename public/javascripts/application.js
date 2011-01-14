

$(document).ready(function() {

  if ($('.buckets.show').length > 0) {
    $.bucket.load();

    $.spinner.bindings();
    $.bucket.bindings();
    $.bucketArchive.bindings();
    $.bucket.editArea.bindings();
    $.bucket.cropImagePopup.bindings();
    $.bucket.uploadBox.bindings();
    $.bucket.newFolderBox.bindings();
  }

  $('.bucketContainer .header select#bucket').change(function(option) {
    var option = $(this).find('option:selected');
    if (window.location != option.val())
      window.location = option.val();
  });

  $.stdDialog.bindings();

  $('.destroyLink').click(function() {
    if (confirm($(this).attr('data-confirm'))) {
      $.post($(this).attr('href'), [ {name: '_method', value: 'delete'} ], function(data) {
        var result = parseJSON(data);
        if (result.state == 'win') {
          window.location.reload();
        } else {
          alert(result.msg);
        }
      });
    }
    return false;
  });

});

$.spinner = {
  active: false,
  bindings: function() {
    $(document).bind('ajaxError', function(ev) {
      $.spinner.error();
    });
  },
  show: function() {
    this.active = true;
    $('.header .spinner .icon').show().siblings().hide();
  },
  hide: function() {
    this.active = false;
    $('.header .spinner .icon').hide().siblings().show();
  },
  error: function(msg) {
    var tmp = $('.templates .ajaxError').clone();
    if (msg)
      tmp.find('.message').html(msg);
    $('.header').prepend(tmp).show();
    $.spinner.hide();
    setTimeout(function() {$('.header .ajaxError:last').remove();}, 5000);
  }
}


$.bucket = {
 
  bindings: function() {
    $('.header ul.hierarchy li a').live('click', function() {
      if (!$.spinner.active) {
        $('.buckets.show form').attr('action', $(this).attr('href'));
        $(this).nextAll().remove();
        $.bucket.load();
      }
      return false;
    });

    $('.header .spinner a.refresh').click(function() {
      if (!$.spinner.active) {
        $.bucket.load({fullRefresh: true});
      }
      return false;
    });

    $('.footer a.uploadFile').click(function() {
      if (!$.spinner.active) {
        $.bucket.uploadBox.toggle($(this).attr('href'));
      }
      return false;
    });
    $('.footer a.newFolder').click(function() {
      if (!$.spinner.active) {
        $.bucket.newFolderBox.toggle();
      }
      return false;
    });
  },

  /*
   * Start loading the bucket archives base on the provided url, or the one
   * currently set in the buckets form.
   */
  load: function(options, callback) {
    var form = $('.buckets.show form');
    var hierarchy = $('.header ul.hierarchy li:first');
    // prepare options
    options = $.extend({
      fullRefresh: false,
      url: form.attr('action'),
      hideEditArea: true
    }, options);

    $('.buckets.show .archives ul').empty();
    $.spinner.show(); 
    if (options.hideEditArea)
      $.bucket.editArea.hide();
    $.bucket.uploadBox.hide();
    $.bucket.newFolderBox.hide();
    $.get(options.url, [ {name: 'full_refresh', value: options.fullRefresh} ], function(data) {
      var result = parseJSON(data);
      hierarchy.siblings().remove();
      $.bucket.newFolderBox.setParent(result.parent_id);
      $('.footer a.uploadFile').attr('href', result.new_archive_url);
      $('.footer a.createFolder').attr('href', result.new_folder_url);
      $.each(result.hierarchy, function(i, archive) {
        var temp = hierarchy.clone();
        temp.find('a').attr('href', archive.edit_url).html(archive.display_name);
        hierarchy.after(temp);
      });
      $.each(result.archives, function(i, archive) {
        $.bucketArchive.show($('.buckets.show .archives ul'), archive);
      });
      $.spinner.hide();
      if (callback) callback();
    });
  },


  editArea: {
    width: "265px",
    content: function() {
      return $('.editArea .content');
    },
    spinner: function() {
      this.content().empty();
      this.content().html( this.content().siblings('.spinner').clone() );
    },
    bindings: function() {
      $('.editArea .close a').live('click', function() {
        if (!$.spinner.active) {
          $('.buckets.show .archives li').removeClass('selected');
          $.bucket.editArea.hide();
        }
        return false;
      });
      $('.editArea form.delete button').live('click', function() {
        if (!$.spinner.active) {
          var form = $(this).parents('form');
          if (confirm($(this).find('.confirm').html())) { $.bucketArchive.destroy(form); }
        }
        return false;
      });
      $('.editArea form.createCopy button').live('click', function() {
        if (!$.spinner.active)
          $.bucketArchive.create($(this).parents('form'));
        return false;
      });
      $('.editArea .defineCrop').live('click', function() {
        if ($(this).attr('checked'))
          $.bucket.cropImagePopup.show();
      });
    },
    show: function() {
      var area = $('.editArea');
      if (area.css('right') != "0px")
        area.animate({right: "0px"})
      $('.buckets.show').css({'margin-right': this.width});
    },
    hide: function() {
      var area = $('.editArea');
      if (area.css('right') != "-"+this.width)
        area.animate({right: "-"+this.width})
      $('.buckets.show').css({'margin-right': "0px"});
    }
  },

  cropImagePopup: {
    api: undefined,
    bindings: function() {
      $('.cropImagePopup button').live('click', function() {
        $.bucket.cropImagePopup.api.destroy();
        $('.cropImagePopup').hide();
      });
    },
    // Better to set image early on to avoid image size detection bugs
    setImage: function(img) {
      $('.cropImagePopup img').attr('src', img);
    },
    show: function(img) {
      $('.cropImagePopup').show();
      if (img) this.setImage(img);
      this.api = $.Jcrop('.cropImagePopup img', {
        onSelect: this.update      
      });
    },
    update: function(c) {
      var area = $('.editArea');
      area.find('#crop_x').val(c.x);
      area.find('#crop_y').val(c.y);
      area.find('#crop_width').val(c.w);
      area.find('#crop_height').val(c.h);
    }
  },

  uploadBox: {

    bindings: function() {
      $('.footer ul li.uploaded:not(.template) a').live('click', function() {
        if (!$.spinner.active) {
          $.bucket.load({url: $(this).attr('href')});   
          $(this).parents('li').remove();
        }
        return false;
      });
    },

    toggle: function(url) {
      if ($('.uploadBox').css('bottom') == "-70px") {
        this.show(url);
      } else {
        this.hide();
      }
    },

    /*
     * Show the upload box
     */
    show: function(url) {
      $.spinner.show();
      $.bucket.newFolderBox.hide();
      $.get(url, '', function(data) {
        var result = parseJSON(data);
        $('.uploadBox').html(result.view);
        $('.uploadBox').animate({bottom: "20px"});
        var item;
        // submit the form
        $('.uploadBox form').ajaxForm({
          iframe: true, dataType: 'json',
          beforeSubmit: function() {
            if ($('.uploadBox form input').val() == '') {
              alert('Missing file!');
              return false;
            }
            // Add the uploading item
            item = $('.footer ul li.uploading.template').clone();
            item.removeClass('template'); 
            item.attr('title', $('.uploadBox input:file').val());
            $('.footer ul').append(item);
            $.bucket.uploadBox.hide();
            return true;
          },
          progress: function(evt) {
            console.log("PROGRESS EVENT!");
            if (evt.lengthComputable && evt.total != 0) {
              item.attr('title', (100*evt.loaded/evt.total)+'%');
            }
          },
          success: function(data) {
            var temp = $('.footer li.uploaded.template').clone();
            temp.removeClass('template');
            temp.find('a').attr('href', data.archives_url).attr('title', data.key);
            item.replaceWith(temp);
          }
        });
         
        $.spinner.hide();
      });
    },

    hide: function() {
      $('.uploadBox').animate({bottom: "-70px"});
    },
  },

  newFolderBox: {
    bindings: function() {
      $('.newFolderBox form').submit( function() {
        if (!$.spinner.active) 
          $.bucket.newFolderBox.submit();
        return false;
      });
    },

    // Set the parent id
    setParent: function(id) {
      $('.newFolderBox #parent_id').val(id);
    },

    submit: function() {
      var form = $('.newFolderBox form')
      $.spinner.show();
      $.post(form.attr('action'), form.serializeArray(), function(data) {
        var result = parseJSON(data);
        $.spinner.hide();
        if (result.state == 'win') {
          $.bucket.newFolderBox.reset();
          $.bucket.load();
        } else {
          alert(data.msg);
        }
      });
    },

    toggle: function() {
      if ($('.newFolderBox').css('bottom') == "20px") {
        this.hide();
      } else {
        this.show();
      }
    },

    show: function() {
      $.bucket.uploadBox.hide();
      $('.newFolderBox').animate({bottom: "20px"});
    },

    reset: function() {
      $('.newFolderBox').find('input#archive_display_name').val('');
      $.bucket.newFolderBox.hide();
    },
    hide: function() {
      $('.newFolderBox').animate({bottom: "-70px"});
    }
  },

  /*
   * Monitor a set of archives and list them on the bottom bar.
   * Useful for archives with an updating state.
   */
  archiveQueue: {
    add: function(archive) {
    }

  }

}

$.bucketArchive = {

  /*
   * Configure bindings for each archive, actions are live, this should only be called once.
   */
  bindings: function() {
    $('li.archive.folder a').live('click', function() {
      if (!$.spinner.active) {
        $('.buckets.show form').attr('action', $(this).attr('href'));
        $.bucket.load();
      }
      return false;
    });

    $('li.archive.image a').live('click', function() {
      if (!$.spinner.active) { 
        $.bucketArchive.edit($(this).parents('li.archive'));
      }
      return false;
    });
    $('li.archive.file a').live('click', function() {
      if (!$.spinner.active) { 
        $.bucketArchive.edit($(this).parents('li.archive'));
      }
      return false;
    });



  },

  /*
   * Show the provided archive object data, by adding it to the 
   * current bucket list.
   */
  show: function(archiveList, archive) {
    // take the template and add it
    var temps = $('.templates')
    var temp = temps.find('.archive.show').clone();
    var icon = '';
    temp.attr('id', "archive_"+archive.id);
    temp.find('a').attr('href', archive.edit_url);
    if (archive.is_folder) {
      temp.addClass('folder');
      icon = temps.find('.icons img.folder').attr('src');
    } else if (archive.is_image) {
      temp.addClass('image');
      icon = temps.find('.icons img.image').attr('src');
    } else {
      temp.addClass('file');
      icon = temps.find('.icons img.file').attr('src');
    }
    temp.find('.icon img').attr('src', archive.thumbnail.icon_url || icon);
    temp.find('.name').html(archive.display_name);
    temp.find('.date').html(archive.date);
    archiveList.append(temp);
  },

  /*
   * Show the edit/view pane with the archive.
   * Expects a target area that contains the archive basic details.
   */
  edit: function(target) {
    $.spinner.show(); 
    target.addClass('selected').siblings().removeClass('selected');
    $.bucket.editArea.show();
    $.bucket.editArea.spinner();
    $.get(target.find('a').attr('href'), '', function(data) {
      var result = parseJSON(data);
      $.bucket.editArea.content().html(result.view);
      addClippy($.bucket.editArea.content().find('.url .copy'), result.archive.public_url);
      $.spinner.hide();
      if (result.archive.updating) {
        $.bucketArchive.checkForChanges.start(result.archive, 'updating');
      } else if (result.loading_thumbnail) {
        $.bucketArchive.checkForChanges.start(result.archive, 'thumb');
      } else {
        // Update the archive with the latest icon
        $.bucketArchive.updateThumbnails(result.archive);
      }
      // Update the cropImage ready to be used
      $.bucket.cropImagePopup.setImage(result.archive.public_url);      
    });
  },

  /*
   * Send a request to create the archive.
   */
  create: function(form) {
    $.spinner.show();
    $.post(form.attr('action'), form.serializeArray(), function(data) {
      var result = parseJSON(data);
      if (result.state == 'win') {
        var archiveId = '#archive_' + result.archive.id;
        // Refresh and edit
        $.bucket.load({hideEditArea: false}, function() {
          $.bucketArchive.edit($(archiveId));
        });
      } else {
        $.spinner.error(result.msg);
      }
    });
  },

  /*
   * Send periodic checks to the server for the currently visible archive.
   *
   * If the archive is now longer visible in the edit window, no more checks will be performed.
   *
   * TODO: Fix the potential issue of bubbling requests, i.e. if user decides to press the edit 
   * archive button lots of times.
   */
  checkForChanges: {
    start: function(archive, type) {
      if (!archive._intervalCount)
        archive._intervalCount = 0;
      archive._intervalCount += 1;
      if (archive._intervalCount < 10) {
        setTimeout(function() { $.bucketArchive.checkForChanges.check(archive, type); }, 4000);
      } else {
        $('#edit_archive_'+archive.id).find('.thumb img').attr('src', $('.templates .icons img.image').attr('src'));
      }
    },
    check: function(archive, type) {
      // only check if the archive is still around
      if ($('#edit_archive_'+archive.id).length > 0) { 
        $.get(archive.url, '', function(data) {
          var result = parseJSON(data);
          var id = 'archive_' + result.id;
          if (type == 'updating') {
            if (!result.updating) {
              // archive has been updated, reload the edit pane
              $.bucketArchive.edit($('#'+id));
              $.bucketArchive.updateThumbnails(result);
              return;
            }
          } else if (type == 'thumb') {
            if (result.thumbnail.url) {
              $.bucketArchive.updateThumbnails(result);
              return;
            }
          }
          $.bucketArchive.checkForChanges.start(archive, type);
        });
      }
    }
  },

  /*
   * If the archive button is arround, update its icon
   */
  updateThumbnails: function(archive) {
    $('#archive_'+archive.id).find('.icon img').attr('src', archive.thumbnail.icon_url+"?"+archive.updated);
    $('#edit_archive_'+archive.id).find('.thumb img').attr('src', archive.thumbnail.url+"?"+archive.updated);
  },

  /*
   * Send a destroy command using the provided form object 
   */
  destroy: function(form) {
    $.spinner.show();
    $.post(form.attr('action'), form.serializeArray(), function(data) {
      var result = parseJSON(data);
      if (result.state == 'win') {
        $.bucket.load();
      } else {
        $.spinner.error(result.msg);
      }
      $.spinner.hide();
    });
  }

}

$.stdDialog = {

  bindings: function() {
    // Bind to generic dialog link (not live!)
    $('a.dialogLink').click(function() {
      $.stdDialog.show($(this).attr('data-title'));
      $.get($(this).attr('href'), '', function(data) {
        var result = parseJSON(data);
        $.stdDialog.html(result.view);
      });
      return false;
    });

    $('#dialog form button[type=submit]').live('click', function() {
      var form = $(this).parents('form');
      $.stdDialog.loading();
      $.post(form.attr('action'), form.serializeArray(), function(data) {
        var result = parseJSON(data);
        if (result.state == 'win') {
          window.location.reload();
        } else {
          $.stdDialog.html(result.view);
        }
      });
      return false;
    });
  },

  show: function(title, contents, options) {
    options = $.extend({
        title: title,
        modal: true, draggable: true,
        position: ['center', 40],
        width: 460, // height: 405,
        dialogClass: 'simple',
        close: function() {
          $('#dialog').dialog('destroy');
        }
      }, options);
    if (!contents || contents == '')
      this.loading();
    else
      $('#dialog').html(contents);
    return $('#dialog').dialog(options).dialog('open');
  },

  loading: function() {
    this.html($('#dialogLoading').html());
  },

  html: function(contents) {
    if (contents)
      $('#dialog').html(contents);
    else
      return $('#dialog').html();
  },

  hide: function() {
    $('#dialog').dialog('close');
  }

}




/*
 * Add the clippy via AJAX
 */
function addClippy(target, text, bgcolor) {
  if (!bgcolor)
    bgcolor = "#ffffff";
  target.flash(
    { 
      swf: '/clippy.swf', height: 14, width: 110,
      params: {
        bgcolor: bgcolor,
        flashvars: {
          text: text
        }
      }
    }
  );
}


/*
 * Check if the provided data is JSON and return a JS object or nil
 */
function parseJSON(data) {
  if (data.charAt(0) == '{') {
    return JSON.parse(data);
  } else {
    return null;
  }
}


