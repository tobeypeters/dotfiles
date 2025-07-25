import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClientProvider } from '@tanstack/react-query';
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import { client } from './QueryClient';
import { Error404 } from './pages/Error404';
import App from './App';

const route = createBrowserRouter([
  {
    path: '/',
    element: <App />,

    errorElement: <Error404 />
  },
  {
    path: "*",

    element: <Error404 />
  },
]);

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <QueryClientProvider client={client}>
      <RouterProvider router={route} />
    </QueryClientProvider>
  </React.StrictMode>);