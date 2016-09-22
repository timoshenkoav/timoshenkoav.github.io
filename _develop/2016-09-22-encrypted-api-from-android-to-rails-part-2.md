---
layout: post
title:  Encrypted API from android to rails part 2
date:   2016-09-22 14:31:18
tags: 
- android 
- rails
related_id: 12
meta_description: Second part of post about passing encrypted data from android client to rails server
read_more:
- 1
---

In previous <a href="/develop/2015-10-02-android-encrypted-api-with-rails/">post</a>, i've described how to create and send encrypted with one time cypher data to server, now its time to receive this data on server side. I will not describe how to setup environment and deploy it some server.

We have encrypted key in request header, and encrypted with this key our 'very secure data' in the request body:

{%highlight ruby%}
x_api = # get header with encrypted key
raw_data = # get raw data from body

api_crypt = APICrypt.new
params = api_crypt.decrypt(x_api, raw_data)
{%endhighlight%}

Class **APICrypt** to deal with this data and key to return decrypted parameters


{%highlight ruby%}
class APICrypt
  AES_MODE = 'AES-256-ECB'
  AES_KEY_SIZE = 256/8
  def decrypt(x_api, data)
    key = Base64.decode64(x_api)
    aes_key = private_key.private_decrypt(key)
    AESCrypt.decrypt(Base64.decode64(data), aes_key, nil, AES_MODE)
  end

  private

  def private_key
    OpenSSL::PKey::RSA.new(File.read(ENV['API_PRIVATE_KEY']))
  end

end
{%endhighlight%}

Helper module to perform AES decryption

{%highlight ruby%}
require 'openssl'

module AESCrypt
 
  def AESCrypt.decrypt(encrypted_data, key, iv, cipher_type)
    aes = OpenSSL::Cipher::Cipher.new(cipher_type)
    aes.decrypt
    aes.key = key
    aes.iv = iv if iv != nil
    aes.update(encrypted_data) + aes.final
  end

{%endhighlight%}


