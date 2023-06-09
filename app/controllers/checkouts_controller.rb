class CheckoutsController < ApplicationController
    skip_before_action :is_authorized, :only => [:create, :complete]
    
<<<<<<< HEAD
=======
    # Stripe.api_key = 'sk_test_51NGEqeCGX7XPMDHf8F2hkgKWMTldXx5PIUVuMm35dB30PQ1HnEWaKxVAZ0dttDRZKV0oxrK9CrIWu7atJe6Oa0yp00Vagwoyqp'

>>>>>>> b7b95d4 (updated checkouts controller)
    def create
        dev_url = "http://localhost:8000"
        prod_url = ""

        session = Stripe::Checkout::Session.create({
<<<<<<< HEAD
			metadata: {
				order_id: params['metadata']["order_id"]
			},
			shipping_address_collection: {allowed_countries: ['AU']},
			shipping_options: [
            	{
              		shipping_rate_data: {
                		type: 'fixed_amount',
                		fixed_amount: {
                  			amount: 0,
                  			currency: 'aud',
                		},
                		display_name: 'Free shipping',
                		delivery_estimate: {
                  			minimum: {
                    			unit: 'business_day',
                    			value: 5,
                  			},
                  			maximum: {
                    			unit: 'business_day',
                    			value: 7,
                  			},
                		},
              		},
            	},
				{
					shipping_rate_data: {
						type: 'fixed_amount',
						fixed_amount: {
							amount: 1500,
							currency: 'aud',
						},
						display_name: 'Next day air',
						delivery_estimate: {
							minimum: {
								unit: 'business_day',
								value: 1,
							},
							maximum: {
								unit: 'business_day',
								value: 1,
							},
						},
					},
				},
			],
            line_items: create_line_items(params),
=======
          shipping_address_collection: {allowed_countries: ['AU']},
          shipping_options: [
            {
              shipping_rate_data: {
                type: 'fixed_amount',
                fixed_amount: {
                  amount: 0,
                  currency: 'aud',
                },
                display_name: 'Free shipping',
                delivery_estimate: {
                  minimum: {
                    unit: 'business_day',
                    value: 5,
                  },
                  maximum: {
                    unit: 'business_day',
                    value: 7,
                  },
                },
              },
            },
            {
              shipping_rate_data: {
                type: 'fixed_amount',
                fixed_amount: {
                  amount: 1500,
                  currency: 'aud',
                },
                display_name: 'Next day air',
                delivery_estimate: {
                  minimum: {
                    unit: 'business_day',
                    value: 1,
                  },
                  maximum: {
                    unit: 'business_day',
                    value: 1,
                  },
                },
              },
            },
          ],
            line_items: [{
              # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
              price: 'price_1NGXOkHK0jF5AwAIDHPHUyTw',
              quantity: 1,
            }],
>>>>>>> b7b95d4 (updated checkouts controller)
            mode: 'payment',
            success_url: dev_url + '/confirmation',
            cancel_url: dev_url + '?canceled=true',
        })
        render :json => { session: session.url }
    end

	def complete
		endpoint_secret = 'whsec_8916bf7946b1aa7e0b539e14643ce2a4d99d5a04ab10a9fedab1abac2c36c54e'
		event = nil

		begin
			sig_header = request.env['HTTP_STRIPE_SIGNATURE']
			payload = request.body.read
			event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
		rescue JSON::ParserError => e
			render :json => { status: 'Not ok'}, :status => :bad_request
		rescue Stripe::SignatureVerificationError => e
			puts 'bad request'
		end

		if event['type'] == 'checkout.session.completed'
			session = Stripe::Checkout::Session.retrieve({
				id: event['data']['object']['id'],
				expand: ['line_items'],
			})
			
			line_items = session.line_items
			order_id = session.metadata.order_id
			puts "session, #{session}"
			puts "hello, orderID: #{order_id}, Line items: #{line_items}"
			
			
			if order_id == 'None'

				order = Order.new # create a new order
				user = User.find_by email: 'guest@shop.co' # find guest user in DB
				order.user_id = user.id # assign order to the guest user account
				update_order_data(order, session)
			
				products_array = [] #finding products
				line_items["data"].each do | product |
					db_product = Product.find_by product_name: product["description"]
					order.products << db_product
					cart_item = order.cart_items.where({product_id: db_product.id}).first # get individual cart item
					cart_item.update_attribute(:quantity, product["quantity"].to_i) # update quantity in cart item
					# update the stock quantity of each product
					db_product_quantity = db_product.quantity
					db_product.update_attribute(:quantity, (db_product_quantity - product["quantity"].to_i))
				end
				OrderMailer.order_confirmation(order.id).deliver_now

			else

				order = Order.find((order_id).to_i)
				update_order_data(order, session)
				OrderMailer.order_confirmation(order.id).deliver_now

			end

		end

		render :json => { status: 'Ok'}, :status => :ok
	end

	private

	def create_line_items(params)
		arr = []

		params['lineItem'].each do | param |
			item = {
				price_data: {
					currency: 'aud',
					product_data: {
						name: param['name'],
					},
					unit_amount: (param['price'].to_f * 100).to_i
				},
				quantity: param['quantity'].to_i
			}
			arr << item
		end

		arr
	end
		
	def update_order_data (order, session)
		order.orderstatus = 'Payment received'
		order.email = session["customer_details"]["email"]
		order.stripe_payment_intent = session["payment_intent"] 
		order.shipping_cost = (session["shipping_cost"]["amount_total"].to_f / 100)
		order.amount_total = (session["amount_total"].to_f / 100)
		order.amount_subtotal = (session["amount_subtotal"].to_f / 100)
		order.shipping_address = format_shipping_address(session["shipping_details"]["address"])
		order.shipping_name = session["shipping_details"]["name"]
		# deduct cart quantity from stock quantity
		order.cart_items.each do | product |
			cart_quantity = product.quantity
			db_product = Product.find(product.product_id)
			db_product.update_attribute(:quantity, (db_product.quantity - cart_quantity))
		end
		order.save
	end

	def format_shipping_address(shipping_address)
		address = ""
		shipping_address.each do |key, value|
			address +=  " #{value unless value.nil?}"
		end
		address
	end

end
