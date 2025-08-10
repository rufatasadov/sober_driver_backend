const axios = require('axios');

// Test configuration
const BASE_URL = 'http://localhost:3000'; // Adjust port as needed
const TEST_PHONE = '+994501234567';
const TEST_NAME = 'Test Customer';

// Test data
const testOrderData = {
  pickup: {
    coordinates: [49.8516, 40.3777],
    address: 'Baku, Azerbaijan',
    instructions: 'Main entrance'
  },
  destination: {
    coordinates: [49.8516, 40.3777],
    address: 'Baku, Azerbaijan',
    instructions: 'Reception desk'
  },
  payment: {
    method: 'cash'
  },
  customerPhone: TEST_PHONE,
  customerName: TEST_NAME
};

// Test scenarios
async function testCustomerCreation() {
  console.log('🧪 Testing Customer Creation API...\n');

  try {
    // Test 1: Create order with new customer
    console.log('📝 Test 1: Creating order with new customer...');
    const response1 = await axios.post(`${BASE_URL}/orders`, testOrderData);
    
    if (response1.status === 201) {
      console.log('✅ Success: Order created with new customer');
      console.log('📱 Customer ID:', response1.data.order.customer.id);
      console.log('👤 Customer Name:', response1.data.order.customer.name);
      console.log('📞 Customer Phone:', response1.data.order.customer.phone);
      console.log('🆔 Order ID:', response1.data.order.id);
    } else {
      console.log('❌ Failed: Unexpected response status');
    }

    console.log('\n' + '='.repeat(50) + '\n');

    // Test 2: Create order with existing customer (should reuse)
    console.log('📝 Test 2: Creating order with existing customer...');
    const response2 = await axios.post(`${BASE_URL}/orders`, testOrderData);
    
    if (response2.status === 201) {
      console.log('✅ Success: Order created with existing customer');
      console.log('📱 Customer ID:', response2.data.order.customer.id);
      console.log('👤 Customer Name:', response2.data.order.customer.name);
      console.log('📞 Customer Phone:', response2.data.order.customer.phone);
      console.log('🆔 Order ID:', response2.data.order.id);
      
      // Verify same customer ID is used
      if (response1.data.order.customer.id === response2.data.order.customer.id) {
        console.log('✅ Customer ID matches - existing customer reused');
      } else {
        console.log('❌ Customer ID mismatch - new customer created instead');
      }
    } else {
      console.log('❌ Failed: Unexpected response status');
    }

    console.log('\n' + '='.repeat(50) + '\n');

    // Test 3: Create order without customer info (should use current user)
    console.log('📝 Test 3: Creating order without customer info...');
    const orderDataWithoutCustomer = {
      pickup: testOrderData.pickup,
      destination: testOrderData.destination,
      payment: testOrderData.payment
    };
    
    const response3 = await axios.post(`${BASE_URL}/orders`, orderDataWithoutCustomer);
    
    if (response3.status === 201) {
      console.log('✅ Success: Order created without customer info');
      console.log('🆔 Order ID:', response3.data.order.id);
      if (response3.data.order.customer) {
        console.log('📱 Customer included in response');
      } else {
        console.log('ℹ️ No customer info in response (as expected)');
      }
    } else {
      console.log('❌ Failed: Unexpected response status');
    }

    console.log('\n' + '='.repeat(50) + '\n');

    // Test 4: Test validation - missing customer name
    console.log('📝 Test 4: Testing validation - missing customer name...');
    const invalidOrderData = {
      pickup: testOrderData.pickup,
      destination: testOrderData.destination,
      payment: testOrderData.payment,
      customerPhone: '+994507654321'
      // Missing customerName
    };
    
    try {
      const response4 = await axios.post(`${BASE_URL}/orders`, invalidOrderData);
      console.log('❌ Failed: Should have returned validation error');
    } catch (error) {
      if (error.response && error.response.status === 400) {
        console.log('✅ Success: Validation error returned for missing customer name');
        console.log('📝 Error:', error.response.data.error);
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }

    console.log('\n' + '='.repeat(50) + '\n');

    // Test 5: Test phone number cleaning
    console.log('📝 Test 5: Testing phone number cleaning...');
    const orderDataWithSpaces = {
      ...testOrderData,
      customerPhone: ' +994 50 123 45 67 ',
      customerName: 'Spaced Phone Customer'
    };
    
    const response5 = await axios.post(`${BASE_URL}/orders`, orderDataWithSpaces);
    
    if (response5.status === 201) {
      console.log('✅ Success: Order created with spaced phone number');
      console.log('📱 Original phone:', orderDataWithSpaces.customerPhone);
      console.log('📱 Cleaned phone:', response5.data.order.customer.phone);
      
      if (response5.data.order.customer.phone === '+994501234567') {
        console.log('✅ Phone number properly cleaned');
      } else {
        console.log('❌ Phone number not cleaned properly');
      }
    } else {
      console.log('❌ Failed: Unexpected response status');
    }

    console.log('\n🎉 All tests completed!');

  } catch (error) {
    console.error('❌ Test failed with error:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }
}

// Run tests
if (require.main === module) {
  testCustomerCreation();
}

module.exports = { testCustomerCreation };
