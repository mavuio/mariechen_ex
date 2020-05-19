# defmodule MariechenWeb.Shop.Payments.Stripe do
#   # def update_or_create_intent(%{"client_secret" => client_secret} = data)
#   #     when is_binary(client_secret) do
#   # end

#   def update_or_create_intent(amount, data \\ %{}, client_secret \\ nil) do
#     data
#     |> process_data_for_stripe_api(amount)
#     |> post_intent(client_secret)
#   end

#   defp process_data_for_stripe_api(data, nil = _amount), do: data

#   def process_data_for_stripe_api(data, amount) do
#     centamount =
#       Decimal.mult("#{amount}", 100)
#       |> Decimal.to_integer()

#     %{
#       "currency" => "EUR"
#     }
#     |> Map.merge(data)
#     |> Map.put("amount", centamount)
#   end

#   def post_intent(data, client_secret \\ nil) do
#     url =
#       case client_secret do
#         secret when is_binary(secret) -> "payment_intents/#{secret}"
#         _ -> "payment_intents"
#       end

#     case Stripy.req(:post, url, data) |> IO.inspect(label: "mwuits-debug 2020-03-27_21:58 ") do
#       {:ok, response} ->
#         response.body
#         |> Jason.decode()
#         |> case do
#           {:ok, response_data} ->
#             response_data

#           _ ->
#             nil
#         end

#       _ ->
#         nil
#     end
#   end

#   #   curl https://api.stripe.com/v1/payment_intents \
#   # -u sk_test_HUKNp1eAFnKfg4dPAzY6X11Q00U6wB1FAQ: \
#   # -d amount=1099 \
#   # -d currency=eur \
#   # -d "metadata[integration_check]"=accept_a_payment
#   # end
# end
