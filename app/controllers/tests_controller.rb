class TestsController < ApplicationController
  require 'net/http'
  require 'open-uri'
  require 'json'
  require 'page_rankr'
	require 'openssl'
	require 'base64'
	require 'cgi'
  
#city in title
#te subdomeny

	def index

	end

  def raport
  	address_from_form = params[:address]	
  	address_to_check = prepare_address(address_from_form)
  	@show_address = address_to_check
  	robots_address = "http://#{address_to_check}/robots.txt"
    doc = Nokogiri::HTML(open("http://#{address_to_check}")) rescue false
    #doc = Nokogiri::HTML(open("http://www.onet.pl")) rescue false
    
    #pobieramy plik robots.txt, zamieniamy na małe litery, usuwamy spacje
	if doc
		robots_txt = open(robots_address).read.downcase.gsub(" ", "") rescue false
		  #@robots_txt = robots_uri.read
    @h1_msg = check_h1(doc) #1ok
    @title_msg = check_title(doc) #1 ok
    @desc_msg = check_description(doc) #1ok
    @robots_msg = check_robots(doc) # 0 ok
    #jeszcze robots case sens
    if robots_txt
      @rtxt_msg = check_robotstxt(robots_txt) #0ok
    else
			@rtxt_msg = 0 #there is no robots.txt so there is no disalow for bot
    end

    @r301_msg = check_301_redirection(address_to_check) # OK @r301_msg['redirection_301_status'] == 1 
    @wildcard_msg = check_wildcard(address_to_check) # 0 OK
    @https_msg = check_https_copy(address_to_check) # 0 OK
    @w3_results = check_w3val(address_to_check) # OK @w3_results['w3_errors']<1
        # =>     w3_results = {'w3_errors' => w3, 'info_address' => val_address}
    
    images = get_images(doc)
    @images_no_alt = check_images_no_alt(images) # OK 0
    @images_empty_alt = check_images_empty_alt(images) # OK 0
    
    @page_speed = get_pagespeed(address_to_check) #dodokonczenia # OK > 80
    @alexa = get_alexa_rank(address_to_check)
    @page_rank = get_page_rank(address_to_check) #z proxy moze byc problem
    @site = get_site_nr(address_to_check)

    @temp_address_to_check = address_to_check

    moz_data = get_moz_data(address_to_check)	
		if moz_data
			@pda = moz_data.fetch("pda")  
			@ueid = moz_data.fetch("ueid")
			@uid = moz_data.fetch("uid")
			@upa = moz_data.fetch("upa")
		end

		@final_score = count_seo_score(@h1_msg, @title_msg, @desc_msg, @robots_msg, @rtxt_msg, @r301_msg, @wildcard_msg, @https_msg, @w3_results, @images_no_alt, @images_empty_alt, @page_speed)
	end
    #jeszcze czy jeden title
    #czy jeden desc
	end

	def count_seo_score(h1_msg, title_msg, desc_msg, robots_msg, rtxt_msg, r301_msg, wildcard_msg, https_msg, w3_results, images_no_alt, images_empty_alt, page_speed)
		score = 0

		if h1_msg == 1
			score += 10
			h1_error = 0
		else 
			h1_error = 1	
		end

		if title_msg == 1
			score += 10
			title_error = 0
		else
			title_error = 1
		end

		if desc_msg == 1
			score += 5
			desc_error = 0
		else 
			desc_error = 1
		end

		if robots_msg == 1
			robots_error = 1
			else 
			score += 10
			robots_error = 0
		end

		if rtxt_msg == 0
			rtxt_error = 0
			score += 10
		else 
			rtxt_error = 1
		end

		if r301_msg['redirection_301_status'] == 1
			score += 10
			r301_error = 0
		else 
			r301_error = 1
		end

		if wildcard_msg == 0
			score += 10
			wildcard_error = 0
		else 
			wildcard_error = 1
		end

		if https_msg == 0
			score += 10
			https_error = 0
		else 
			https_error = 1
		end

		if w3_results['w3_errors'] < 1
			score += 5
			w3_error = 0
		else
			w3_error = 1
		end

		if images_no_alt.blank?
			score += 5
			images_no_alt_error = 0
		else 
			images_no_alt_error = 1
		end

		if images_empty_alt.blank?
			score += 5
			images_empty_alt_error = 0
		else
			images_empty_alt_error = 1
		end

		if page_speed > 80 
			score += 10
			page_speed_error = 0
		else 
			page_speed_error = 1
		end

		score_results = Hash.new
    score_results = {
    	'score' => score, 
    	'h1_error' => h1_error, 
    	'title_error' => title_error, 
    	'desc_error' => desc_error, 
    	'robots_error' => robots_error,
    	'rtxt_error' => rtxt_error,
    	'r301_error' => r301_error,
			'wildcard_error' => wildcard_error,
			'https_error' => https_error,
			'w3_error' => w3_error,
			'images_empty_alt_error' => images_empty_alt_error,
			'images_no_alt_error' => images_no_alt_error,
			'page_speed_error' => page_speed_error    	
    }

		return score_results

	end

  def title
#api
#AIzaSyBJcAvAu1Dz9Bk4x7xn1b0Yg9PSVJkMrU4   
#speed_info = open("https://www.googleapis.com/pagespeedonline/v1/runPagespeed?url=http://scarto.pl/&key=AIzaSyBJcAvAu1Dz9Bk4x7xn1b0Yg9PSVJkMrU4").read
#jdoc = JSON.parse(speed_info)
#@ps = jdoc.fetch("title")  

  end


  def temp
   one = "http://www.transfermarkt.de/oscar/profil/spieler/85314"  
   val_address = "http://www.transfermarkt.de/fc-chelsea/startseite/verein/631/saison_id/2014"
   w3doc = Nokogiri::HTML(open(one)) rescue false
  #alx = alexa_doc.xpath('//div[@class="rank-row"]').xpath('//strong[@class="metrics-data align-vmiddle"]').first.to_s.gsub(/[^0-9]/, '').to_i
   
    if w3doc       
      @players = w3doc.xpath('//td[@class="hauptlink"]')
      player_name = w3doc.xpath('//div[@class="spielername-profil"]/text()')
      @data = w3doc.xpath('//table[@class="profilheader"]/tr')
      @player_array = Array.new
      @player_array.clear
      @player_array.push(player_name)

      @data.each do |z|
        if z.to_s.include?("Geburtsdatum")
          after = z.xpath('//td[@class="wsnw"]/text()')    
          @player_array.push(after)      
        elsif z.to_s.include?("Marktwert")
          @player_array.push(z.to_s.gsub(/[^0-9^,]/, ''))
        elsif z.to_s.include?("Nationalität")
          after = z.content.to_s.gsub("Nationalität:","")    
          @player_array.push(after)        
        elsif z.to_s.include?("Größe")
          #@player_array.push(z) 
        end
      end
      #CSV.open("file1.csv", "w+") do |csv|
      #      csv << [z]
      #end
    
    end
  end

  def temp2

 
  end


private

  # redirection check - there should be a 301 redirection 
  # non_www -> 301 -> www OR
  # www -> 301 -> non www
  def check_301_redirection(address)

	#todo - jeszcze jak jest subka podana to sprawdzenie robić dla subki - maklerska.opole.pl

  	non_www_version = get_http_status(address)
  	www_version = get_http_status("www.#{address}")
    
    if non_www_version != '301' && www_version != '301'
      r301_status = 0
  	  current_version = ""
  	  #common mistake is to set 302 redirection insted of 301	
      if non_www_version == '302' or www_version == '302'
        r302_status = 1
      end	
  
    else #there is a 301 redirection
      #lets see which version has 200 status	
      if non_www_version == '200'
        current_version = address
      elsif www_version == '200'
        current_version = "www.#{address}"
      end	
      r301_status = 1
      r302_status = 0
    end
    results_301 = Hash.new
    results_301 = {'redirection_301_status' => r301_status, 'redirection_302_status' => r302_status, 'redirected_to' => current_version}
    return results_301
  end

  #sometimes wildcard is on when it is not necessary
  #and it can make many copies of main page
  def check_wildcard(address)
  	rand = ('a'..'z').to_a.shuffle[0,8].join
  	random_subdomain = "#{rand}.#{address}"
	  if get_sub_http_status("http://#{random_subdomain}") == '200'
  		wildcard_msg = 1
  	else
  		wildcard_msg = 0
  	end
   return wildcard_msg	
  end	

  def check_https_copy(address)
  	http_ver = get_sub_http_status("http://#{address}")
  	https_ver = get_sub_http_status("https://#{address}")

  	if http_ver == https_ver and http_ver == 200
  	  https_msg = 1	
  	else
  	  https_msg = 0	
  	end
  	return https_msg
  end

  #simple method which get response code
  def get_http_status(address)
	http = Net::HTTP.new(address,80)
    response = http.request_get('/')
    return response.code rescue false
  end	

  def check_title(doc)
      title = doc.title
      if title.blank?
      	title_msg = 0
      else
      	title_chars = title.length
      	if title_chars < 70 and title_chars > 1
      	  title_msg = 1	
      	elsif title_chars > 70
      	  title_msg = 2	
      	elsif title_chars <1
      	  title_msg = 0	
      	end
      end
      return title_msg
  end

  def check_description(doc)
  	# check if there is a description metatag and does it have a proper lenght?
  	# there is no way to do a downcase and Nokogiri is case sensitive so this is an ugly solution
  	# we check 3 possibilities:
  	# meta name="Description"
  	# meta name="description"
  	# meta name="DESCRIPTION"
  	# if none is found, then there is an error 
    meta_names = Array["Description", "description", "DESCRIPTION"]
	  @meta_errors = 0
	  meta_names.each do |q|
	    all_desc = doc.at("meta[@name=\"#{q}\"]")
	    if all_desc #if there is a meta description, go on
		    @description_full = all_desc['content']
		    if @description_full
			    description = @description_full
		 	    if description.blank? #we check if desc is empty
			      desc_msg = 0
		      else #if not, we want to make sure that descriptions length is proper
		        desc_chars = description.length
		          if desc_chars < 150 and desc_chars > 1
		      	    desc_msg = 1 #length OK
		          elsif desc_chars > 150
		      	    desc_msg = 2 # too long
		          elsif desc_chars <1
		      	    desc_msg = 0 #empty
		          end	
		      end
		      return desc_msg
		    end  
	    else
	    	# as staded before, we look for 3 variants (description, Description, DESCRIPTION)
	    	# if one is found (correct), meta errors will be 2
	    	# if none is found (no description found at all) then meta errors will be 3
	    	# if meta_errors will be less then 2, then it is possible that there are two diff descriptions ;)
	    	@meta_errors += 1
	    end
	 end
  end

  def check_h1(doc) 
      # h1_tag = doc.at("h1") <- this will only find <h1>text</h1> but sometimes
      # we have sth. like <h1><a href="">bla bla</a></h1> and doc.at don't read it properly
      # xpath solves this problem because it doesn't care about h1 content 
	    h1_tag = doc.xpath('//h1')
	    if h1_tag.blank?
	  	h1_msg = 0
	  else
	    h1_nr = h1_tag.count
	    if h1_nr == 1 
	  	  h1 = h1_tag.xpath('//h1')
	  	  h1_msg = 1
	    elsif h1_nr > 1
	  	  h1_msg = 2
	    end
	  end 
	  return h1_msg
  end

  def check_robots(doc)
    robots_full = doc.at("meta[name='robots']")
	  
	  if robots_full
		robots = robots_full['content']

		if robots.match('noindex')
	      robots_msg = 1 
	    else
	      robots_msg = 0 
	    end
	  return robots_msg    
	  end   
  end

  def check_robotstxt(robots_content)
  	if robots_content
  		new_line = "\n"
  		#fragments which may block google bot to access website
  		disallow_fragment = "user-agent:*#{new_line}disallow:/#{new_line}"
  		disallow_fragment_g = "user-agent:googlebot#{new_line}disallow:/#{new_line}"
  		
  	  if robots_content.include? disallow_fragment or robots_content.include? disallow_fragment_g
  	  	rtxt_msg = 1
  	  else
  	  	rtxt_msg = 0
  	  end
  	  return rtxt_msg
  	end
  end

  def get_images(doc)
	#html = Nokogiri::HTML(open(address_to_check)) rescue false
	imgs = doc.xpath('//img')
	return imgs
  end
  	
  def check_images_no_alt(images)
	
	images_no_alt = Array.new
	
	images.each do |f|
		current_f = f.to_s.downcase
		unless current_f.include? "alt="
		  images_no_alt.push(current_f)
		end
	end
  	return images_no_alt
  end

  def check_images_empty_alt(images)
	
	images_empty_alt = Array.new

	images.each do |f|
		current_f = f.to_s.downcase
		if current_f.include? "alt=''"
	      images_empty_alt.push(current_f)
		end
	end
  	return images_empty_alt
  end

#--------------------------------------------------------------
# w3validator
#--------------------------------------------------------------

  def check_w3val(address)
   val_address = "http://validator.w3.org/check?uri=#{address}&charset=%28detect+automatically%29&doctype=Inline&group=0"
   w3doc = Nokogiri::HTML(open(val_address)) rescue false
   
   if w3doc		   
     h3_tag = w3doc.xpath('//h3[@class="invalid"]')
     #h3_tag is now like:
     #<h3 class="invalid">Validation Output: 58 Errors </h3>

     #now we want to find only numbers, first we convert to string to use gsub,
     #then delete h3, (because they have nrs in it), and delete all chars which are not numbers
     #and convert to integer 
     get_error_nr = h3_tag.to_s.gsub("h3", "").gsub(/[^0-9]/, '').to_i
     if get_error_nr
     	 w3 = get_error_nr
     else
       w3 = 0
     end
   end
		w3_results = Hash.new
    w3_results = {'w3_errors' => w3, 'info_address' => val_address}
    return w3_results
  end

#--------------------------------------------------------------
# PageSpeed API
#--------------------------------------------------------------

  def get_pagespeed(address)
	#tu jak zrobisz juz FORM to trzeba bedzie dodac opcje ze onclick przekazuje val
	#api
	#AIzaSyBJcAvAu1Dz9Bk4x7xn1b0Yg9PSVJkMrU4   
	speed_info = open("https://www.googleapis.com/pagespeedonline/v1/runPagespeed?url=http://#{address}&key=AIzaSyBJcAvAu1Dz9Bk4x7xn1b0Yg9PSVJkMrU4").read
	jdoc = JSON.parse(speed_info)
	score = jdoc.fetch("score")  
	return score
  end

#--------------------------------------------------------------
#PageRankr - start
#--------------------------------------------------------------
  def get_alexa_rank(address)
   #alexa_address = "http://www.alexa.com/siteinfo/#{address}"
   #alexa_doc = Nokogiri::HTML(open(alexa_address)) rescue false
   #alx = alexa_doc.xpath('//div[@class="rank-row"]').xpath('//strong[@class="metrics-data align-vmiddle"]').first.to_s.gsub(/[^0-9]/, '').to_i
	
	rank = PageRankr.ranks(address, :alexa_global) 
  	return rank.fetch(:alexa_global)
  end

  def get_page_rank(address)
	rank = PageRankr.ranks(address, :google) 
  	return rank.fetch(:google)  
  end

  def get_site_nr(address)
  	rank = PageRankr.index(address, :google) 
  	return rank.fetch(:google)  
  end



#--------------------------------------------------------------
# MOZ API - start
#--------------------------------------------------------------

def get_moz_data(address)
# You can obtain you access id and secret key here: http://moz.com/products/api/keys
access_id    = "member-706b3a09d1"
secret_key    = "b6b5ed45bcefcee3e950f8880992bab2"
 
# Set your expires for several minutes into the future.
# Values excessively far in the future will not be honored by the Mozscape API.
expires    = Time.now.to_i + 300
 
# A new linefeed is necessary between your AccessID and Expires.
string_to_sign = "#{access_id}\n#{expires}"
 
# Get the "raw" or binary output of the hmac hash.
binary_signature = OpenSSL::HMAC.digest('sha1', secret_key, string_to_sign)
 
# We need to base64-encode it and then url-encode that.
url_safe_signature = CGI::escape(Base64.encode64(binary_signature).chomp)
 
# This is the URL that we want metrics for.
object_url = address
 
# Add up all the bit flags you want returned.
# Learn more here: http://apiwiki.moz.com/query-parameters/
cols = '103079217184'
 
# Now put your entire request together.
# This example uses the Mozscape URL Metrics API.
request_url = "http://lsapi.seomoz.com/linkscape/url-metrics/#{object_url}?Cols=#{cols}&AccessID=#{access_id}&Expires=#{expires}&Signature=#{url_safe_signature}"
if get_sub_http_status(request_url) == '200'
	##SPRAWDZANIE STATUSU 
	# Go and fetch the URL
	moz_data = open(request_url).read
	mdata = JSON.parse(moz_data)
	return mdata
	# "response" is now the JSON string returned fron the API
end
end


  #get subdomain status
  def get_sub_http_status(address)
    return Net::HTTP.get_response(URI(address)).code rescue false
  end	

# we need to prepare address from form, final address should be 
# like 'domain.com' without http://, without 'www' and
# without '/' or '\' in the end
  def prepare_address(address_from_form)
    #delete http:// and www	
  	temp_string = address_from_form.sub("https://", "").sub("http://", "").sub("www.", "")
    #check if there is a slash in the end
  	if temp_string.last == '/' or temp_string.last == '\\'
  	  string = temp_string.sub(temp_string.last, "") #delete slash (last char)	
  	else #there was no slash in the end so return temp_string
  	  string = temp_string	
  	end
  	return string
  end

end
